"""Offline, development-only typed GLSL subset porter. Never imported by production.

Tokenizes and parses expressions/statements, retains types and lexical scopes,
then lowers GLSL scalar/vector coercion, overloads, constructors and lvalues.
Static outputs must pass the native smoke before catalog enablement.
"""
from __future__ import annotations
import argparse, hashlib, json, re, shutil, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
COMMIT = 'b2dfdcfbec079af4a05306d32b9366aa495c5155'
TYPES = {'float':'f32','int':'i32','bool':'bool','void':'void',**{f'{p}vec{n}':f'vec{n}<{t}>' for p,t in [('', 'f32'),('i','i32'),('b','bool')] for n in (2,3,4)},**{f'mat{n}':f'mat{n}x{n}<f32>' for n in (2,3,4)}}
def ident(x): return 'g_' + x

def tokenize(s):
    s=re.sub(r'/\*.*?\*/|//[^\n]*','',s,flags=re.S)
    s=re.sub(r'\b(?:highp|mediump|lowp)\s+', '', s)
    macros={}
    def define(m):
        name,args,expr=m.group(1),m.group(2),m.group(3)
        macros[name]=(args.split(',') if args is not None else None,expr)
        return ''
    s=re.sub(r'^\s*#define\s+(\w+)(?:\(([^)]*)\))?\s+([^\n]+)',define,s,flags=re.M)
    for _ in range(5):
        for name,(args,expr) in macros.items():
            if args is None: s=re.sub(r'\b'+name+r'\b','('+expr+')',s)
            else:
                # Corpus macro arguments contain no comma; balanced groups handled below.
                pat=re.compile(r'\b'+name+r'\s*\(')
                while (m:=pat.search(s)):
                    i=m.end(); depth=1; j=i
                    while depth:
                        if s[j]=='(': depth+=1
                        if s[j]==')': depth-=1
                        j+=1
                    value=s[i:j-1]; repl=expr
                    for a in args: repl=re.sub(r'\b'+a.strip()+r'\b','('+value+')',repl)
                    s=s[:m.start()]+'('+repl+')'+s[j:]
    token=re.compile(r'\s+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?[fF]?|[A-Za-z_]\w*|\+\+|--|\+=|-=|\*=|/=|==|!=|<=|>=|&&|\|\||[{}()\[\];,.?:+*/%<>=!\-]')
    out=[]; end=0
    for m in token.finditer(s):
        if s[end:m.start()].strip(): raise ValueError('Unsupported token '+s[end:m.start()])
        if not m.group().isspace(): out.append(m.group())
        end=m.end()
    if s[end:].strip(): raise ValueError('Unparsed tail '+s[end:])
    return out+['EOF']

class Parser:
    def __init__(self,s): self.t=tokenize(s); self.i=0; self.structs={}
    def peek(self): return self.t[self.i]
    def pop(self,expect=None):
        x=self.peek(); self.i+=1
        if expect and x!=expect: raise ValueError(f'Expected {expect}, got {x} near {self.t[max(0,self.i-8):self.i+8]}')
        return x
    def eat(self,s):
        if self.peek()==s: self.i+=1; return True
        return False
    def ty(self):
        t=self.pop()
        if self.eat('['): n=self.pop(); self.pop(']'); t=f'array:{t}:{n}'
        return t
    def declarations(self,t,n=None):
        ds=[]
        while True:
            name=n or self.pop(); n=None; typ=t
            if self.eat('['):
                paren=self.eat('('); size=self.pop();
                if paren: self.pop(')')
                self.pop(']'); typ=f'array:{t}:{size}'
            val=self.expr() if self.eat('=') else None
            ds.append((typ,name,val))
            if not self.eat(','): break
        self.pop(';'); return ('decl',ds)
    def program(self):
        out=[]
        while self.peek()!='EOF':
            if self.eat('struct'):
                name=self.pop(); self.pop('{'); members=[]
                while not self.eat('}'):
                    t=self.ty(); n=self.pop(); self.pop(';'); members.append((t,n))
                self.pop(';'); self.structs[name]=members; out.append(('struct',name,members)); continue
            qual=''
            if self.peek() in ('uniform','const'): qual=self.pop()
            t=self.ty(); n=self.pop()
            if self.eat('('):
                args=[]
                while not self.eat(')'):
                    if self.peek() in ('in','const'): self.pop()
                    at=self.ty(); an=self.pop(); args.append((at,an))
                    if not self.eat(','): self.pop(')'); break
                out.append(('fn',t,n,args,self.stmt()))
            else: out.append((qual or 'global',self.declarations(t,n)[1]))
        return out
    def block(self):
        self.pop('{'); ss=[]
        while not self.eat('}'): ss.append(self.stmt())
        return ('block',ss)
    def stmt(self):
        p=self.peek()
        if p=='{': return self.block()
        if self.eat('if'):
            self.pop('('); cond=self.expr(); self.pop(')'); a=self.stmt(); b=self.stmt() if self.eat('else') else None
            return ('if',cond,a,b)
        if self.eat('for'):
            self.pop('('); init=self.stmt(); cond=self.expr(); self.pop(';'); inc=self.expr(); self.pop(')'); return ('for',init,cond,inc,self.stmt())
        if self.eat('return'):
            x=self.expr() if self.peek()!=';' else None; self.pop(';'); return ('return',x)
        if p in ('break','continue','discard'): self.pop(); self.pop(';'); return (p,)
        if self.eat(';'): return ('empty',)
        if p=='const': self.pop(); p=self.peek()
        if p in TYPES or p in self.structs:
            t=self.ty(); return self.declarations(t)
        x=self.expr(); self.pop(';'); return ('expr',x)
    PRE={'=':1,'+=':1,'-=':1,'*=':1,'/=':1,'?':2,'||':3,'&&':4,'==':5,'!=':5,'<':6,'>':6,'<=':6,'>=':6,'+':7,'-':7,'*':8,'/':8,'%':8}
    def expr(self,m=1):
        p=self.pop()
        if p in ('-','+','!','++','--'): x=('unary',p,self.expr(9))
        elif p=='(': x=self.expr(); self.pop(')')
        else: x=('atom',p)
        while True:
            p=self.peek()
            if p=='(':
                self.pop(); args=[]
                while not self.eat(')'):
                    args.append(self.expr())
                    if not self.eat(','): self.pop(')'); break
                x=('call',x,args)
            elif p=='.': self.pop(); x=('field',x,self.pop())
            elif p=='[': self.pop(); ix=self.expr(); self.pop(']'); x=('index',x,ix)
            elif p in ('++','--'): self.pop(); x=('post',p,x)
            else: break
        while self.PRE.get(self.peek(),0)>=m:
            op=self.pop(); pr=self.PRE[op]
            if op=='?': yes=self.expr(); self.pop(':'); no=self.expr(pr); x=('ternary',x,yes,no)
            else: x=('binary',op,x,self.expr(pr if pr==1 else pr+1))
        return x

def width(t): return int(t[-1]) if re.fullmatch('[ib]?vec[234]',t) else 1
def scalar(t): return 'int' if t.startswith('ivec') or t=='int' else 'bool' if t.startswith('bvec') or t=='bool' else 'float'
def wg(t):
    if t.startswith('array:'):
        _,el,n=t.split(':'); return f'array<{wg(el)}, {n}>'
    return TYPES.get(t,ident(t))
def coerce(code,t,want):
    if t==want: return code
    if want=='bool': return f'({code} != {wg(t)}(0))'
    if t=='bool': return f'select({wg(want)}(0), {wg(want)}(1), {code})'
    return f'{wg(want)}({code})'

class Generator:
    def __init__(self,ast,params,structs):
        self.ast=ast; self.params=params; self.structs=structs; self.env={}; self.functions={}; self.globals=[]; self.initial=[]
        for node in ast:
            if node[0]=='fn': self.functions.setdefault(node[2],[]).append(node)
            if node[0] in ('global','const','uniform'):
                for t,n,v in node[1]: self.env[n]=t
        self.env.update(progress='float',ratio='float')
    def expr(self,x):
        k=x[0]
        if k=='atom':
            a=x[1]
            if a in ('true','false'): return a,'bool'
            if re.match(r'^[\d.]',a):
                t='float' if any(c in a for c in '.eEfF') else 'int'
                if a.endswith(('f','F')): a=a[:-1]
                return (a+'0' if a.endswith('.') else '0'+a if a.startswith('.') else a),t
            if a not in self.env: raise ValueError('Unknown identifier '+a)
            return ident(a),self.env[a]
        if k=='field':
            c,t=self.expr(x[1]); f=x[2]
            if t in self.structs: return f'{c}.{ident(f)}',dict((n,t) for t,n in self.structs[t])[f]
            st=scalar(t); typ=st if len(f)==1 else ('i' if st=='int' else 'b' if st=='bool' else '')+'vec'+str(len(f))
            return f'{c}.{f}',typ
        if k=='index':
            c,t=self.expr(x[1]); i,it=self.expr(x[2]); typ=t.split(':')[1] if t.startswith('array:') else 'vec'+t[-1] if t.startswith('mat') else scalar(t)
            return f'{c}[{coerce(i,it,"int")}]',typ
        if k=='unary':
            c,t=self.expr(x[2])
            if x[1]=='+': return c,t
            if x[1] in ('++','--'): return c+(' += ' if x[1]=='++' else ' -= ')+('1.0' if t=='float' else '1'),t
            return f'({x[1]}{c})','bool' if x[1]=='!' else t
        if k=='post':
            c,t=self.expr(x[2]); return (c+' += 1.0' if x[1]=='++' else c+' -= 1.0') if t=='float' else c+x[1],t
        if k=='binary':
            op=x[1]; a,ta=self.expr(x[2]); b,tb=self.expr(x[3]); assign=op in ('=','+=','-=','*=','/=')
            if assign: return self.assign(x[2],a,ta,op,b,tb),ta
            if op in ('&&','||'): return f'({a} {op} {b})','bool'
            if op=='*' and (ta.startswith('mat') or tb.startswith('mat')):
                target=tb if ta.startswith('mat') else ta
                if ta.startswith('mat') and tb.startswith('mat'): target=ta
                return f'({a} * {b})',target
            target=ta if width(ta)>width(tb) else tb if width(tb)>width(ta) else 'float' if 'float' in (ta,tb) else ta
            a=coerce(a,ta,target); b=coerce(b,tb,target)
            if op in ('==','!=') and width(target)>1: return f'{"all" if op=="==" else "any"}({a} {op} {b})','bool'
            return f'({a} {op} {b})','bool' if op in ('==','!=','<','>','<=','>=') else target
        if k=='ternary':
            c,tc=self.expr(x[1]); a,ta=self.expr(x[2]); b,tb=self.expr(x[3]); target=ta if width(ta)>=width(tb) else tb
            return f'select({coerce(b,tb,target)}, {coerce(a,ta,target)}, {c})',target
        if k=='call':
            name=x[1][1]; args=[self.expr(a) for a in x[2]]; cs=[a for a,t in args]; ts=[t for a,t in args]
            if name in TYPES:
                target=name
                if name.startswith('mat'):
                    n=int(name[-1]); flat=[]
                    if len(args)==1 and width(ts[0])==1:
                        for col in range(n): flat.append(f'vec{n}<f32>('+', '.join(coerce(cs[0],ts[0],'float') if col==row else '0.0' for row in range(n))+')')
                    elif len(args)==n*n:
                        flat=[f'vec{n}<f32>('+', '.join(coerce(cs[j],ts[j],'float') for j in range(i,i+n))+')' for i in range(0,n*n,n)]
                    else: flat=cs
                    return f'{wg(name)}('+', '.join(flat)+')',name
                coerced=[]
                for c,t in args:
                    want=scalar(name) if width(t)==1 else ('i' if scalar(name)=='int' else 'b' if scalar(name)=='bool' else '')+'vec'+str(width(t))
                    coerced.append(coerce(c,t,want))
                return f'{wg(name)}('+', '.join(coerced)+')',name
            if name in self.structs: return ident(name)+'('+', '.join(cs)+')',name
            if name in self.functions:
                choices=self.functions[name]
                choices=sorted(choices,key=lambda f:sum(a!=b for a,(b,_) in zip(ts,f[3])))
                fn=choices[0]; name=ident(name)+('__'+ '_'.join(t for t,n in fn[3]) if len(choices)>1 else '')
                return name+'('+', '.join(coerce(c,t,pt) for (c,t),(pt,pn) in zip(args,fn[3]))+')',fn[1]
            if name=='texture2D': return 'textureSampleLevel('+cs[0]+', s_sampler, vec2<f32>(('+cs[1]+').x, 1.0-('+cs[1]+').y), 0.0)', 'vec4'
            if name in ('getFromColor','getToColor'): return name+'('+', '.join(cs)+')','vec4'
            if name in ('dot','length','distance','determinant'): return name+'('+', '.join(cs)+')','float'
            if name in ('all','any'): return name+'('+', '.join(cs)+')','bool'
            if name in ('lessThan','greaterThan','lessThanEqual','greaterThanEqual','equal','notEqual'):
                op={'lessThan':'<','greaterThan':'>','lessThanEqual':'<=','greaterThanEqual':'>=','equal':'==','notEqual':'!='}[name]
                return f'({cs[0]} {op} {cs[1]})','bvec'+str(width(ts[0]))
            if name=='atan' and len(args)==2: name='atan2'
            if name=='mod':
                target=max(ts,key=width); a,b=[coerce(c,t,target) for c,t in args]; return f'({a} - {b} * floor({a} / {b}))',target
            if name=='mix' and scalar(ts[2])=='bool': return 'select('+', '.join(cs)+')',ts[0]
            known={'abs','acos','asin','atan','atan2','ceil','clamp','cos','cross','exp','exp2','floor','fract','inverseSqrt','inversesqrt','log','log2','max','min','mix','normalize','pow','radians','degrees','reflect','round','sign','sin','smoothstep','sqrt','step','tan','transpose','trunc'}
            if name not in known: raise ValueError('Unknown call '+name)
            name='inverseSqrt' if name=='inversesqrt' else name
            target=max(ts,key=width)
            if width(target)==1 and 'float' in ts: target='float'
            return name+'('+', '.join(coerce(c,t,target) for c,t in args)+')',target
        raise ValueError('expression '+str(x))
    def assign(self,node,a,ta,op,b,tb):
        b=coerce(b,tb,ta)
        if node[0]=='field' and len(node[2])>1 and self.expr(node[1])[1] not in self.structs:
            base,bt=self.expr(node[1]); sw=node[2]; comp='xyzw'[:width(bt)]; alias=dict(zip('rgba','xyzw')); sw=''.join(alias.get(c,c) for c in sw)
            vals=[]
            for c in comp:
                v=f'({b}).{"xyzw"[sw.index(c)]}' if c in sw else f'{base}.{c}'
                if c in sw and op!='=': v=f'({base}.{c} {op[0]} {v})'
                vals.append(v)
            return base+' = '+wg(bt)+'('+', '.join(vals)+')'
        return f'{a} {op} {b}'
    def statement(self,s):
        k=s[0]
        if k=='block':
            env=self.env.copy(); text='{\n'+'\n'.join(self.statement(x) for x in s[1])+'\n}'; self.env=env; return text
        if k=='decl':
            lines=[]
            for t,n,v in s[1]:
                rhs=coerce(*self.expr(v),t) if v else None; self.env[n]=t
                lines.append(f'var {ident(n)}: {wg(t)}'+(' = '+rhs if rhs else '')+';')
            return '\n'.join(lines)
        if k=='expr':
            x=s[1]
            if x[0]=='binary' and x[1]=='=' and x[3][0]=='binary' and x[3][1]=='=':
                return self.statement(('expr',x[3]))+'\n'+self.statement(('expr',('binary','=',x[2],x[3][2])))
            return ('_ = ' if x[0]=='call' else '')+self.expr(x)[0]+';'
        if k=='return': return 'return'+(' '+coerce(*self.expr(s[1]),self.ret) if s[1] else '')+';'
        if k=='if': return 'if ('+self.expr(s[1])[0]+') '+self.brace(s[2])+(' else '+self.brace(s[3]) if s[3] else '')
        if k=='for':
            env=self.env.copy(); a=self.statement(s[1]).rstrip(';'); b=self.expr(s[2])[0]; c=self.expr(s[3])[0]; body=self.brace(s[4]); self.env=env
            return f'for ({a}; {b}; {c}) '+body
        if k in ('break','continue','discard'): return k+';'
        if k=='empty': return ''
        raise ValueError('statement '+str(s))
    def brace(self,s): return self.statement(s) if s[0]=='block' else '{\n'+self.statement(s)+'\n}'
    def generate(self):
        fields=['progress','ratio']; runtime=[]
        for p in self.params:
            n=p['name']; t=p['glsl_type']; w=width(t)
            fs=[n] if w==1 else [n+'_'+c for c in 'xyzw'[:w]]
            fields.extend(fs)
        padded=fields+[f'_pad{i}' for i in range((-len(fields))%4)]
        pre='struct Params {\n'+''.join('  '+n+': f32,\n' for n in padded)+'};\n'+HEADER
        out=[]; inits=[]
        for n in ('progress','ratio'): out.append('var<private> '+ident(n)+': f32;'); inits.append(ident(n)+' = params.'+n+';')
        for p in self.params:
            n=p['name']; t=p['glsl_type']; w=width(t); out.append('var<private> '+ident(n)+': '+wg(t)+';')
            if w==1: val=coerce('params.'+n,'float',t)
            else: val=wg(t)+'('+', '.join(coerce('params.'+n+'_'+c,'float',scalar(t)) for c in 'xyzw'[:w])+')'
            inits.append(ident(n)+' = '+val+';')
        for node in self.ast:
            k=node[0]
            if k=='struct': out.insert(0,'struct '+ident(node[1])+' {\n'+''.join(ident(n)+': '+wg(t)+',\n' for t,n in node[2])+'};')
            if k in ('global','const'):
                for t,n,v in node[1]:
                    out.append('var<private> '+ident(n)+': '+wg(t)+';')
                    if v: inits.append(ident(n)+' = '+coerce(*self.expr(v),t)+';')
            if k=='fn':
                _,ret,n,args,body=node; old=self.env.copy(); self.env.update({n:t for t,n in args}); self.ret=ret
                fn=ident(n)+('__'+'_'.join(t for t,n in args) if len(self.functions[n])>1 else '')
                argtext=', '.join('a_'+n+': '+wg(t) for t,n in args)
                b=self.statement(body); b=b[1:]; locals=''.join('var '+ident(n)+': '+wg(t)+' = a_'+n+';\n' for t,n in args)
                out.append('fn '+fn+'('+argtext+')'+(' -> '+wg(ret) if ret!='void' else '')+' {\n'+locals+b); self.env=old
        fragment='@fragment\nfn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {\n'+'\n'.join(inits)+'''\nlet uv = vec2<f32>(input.tex_coords.x, 1.0-input.tex_coords.y);
let raw = g_transition(uv);
let alpha = clamp(raw.a, 0.0, 1.0);
return vec4<f32>(clamp(raw.rgb, vec3<f32>(0.0), vec3<f32>(alpha)), alpha);
}\n'''
        extra=[n for n,t in self.env.items() if t=='sampler2D']
        if extra:
            pre=pre.replace('@binding(2) var s_sampler',f'@binding({2+len(extra)}) var s_sampler').replace('@binding(3) var<uniform>',f'@binding({3+len(extra)}) var<uniform>')
            pre+='\n'+'\n'.join(f'@group(0) @binding({i+2}) var {ident(n)}: texture_2d<f32>;' for i,n in enumerate(extra))
        result=pre+'\n'+'\n'.join(out)+'\n'+fragment
        for reserved in ('type','var','const','override','let','fn'):
            result=result.replace('  '+reserved+': f32,','  p_'+reserved+': f32,')
            result=re.sub(r'\bparams\.'+reserved+r'\b','params.p_'+reserved,result)
        return result

HEADER='''
struct VertexInput {
 @location(0) position: vec2<f32>,
 @location(1) tex_coords: vec2<f32>,
 @location(2) color: vec4<f32>,
};
struct VertexOutput {
 @builtin(position) clip_position: vec4<f32>,
 @location(0) tex_coords: vec2<f32>,
};
@vertex fn vs_main(input: VertexInput) -> VertexOutput {
 var out: VertexOutput;
 out.clip_position=vec4<f32>(input.position,0.0,1.0);
 out.tex_coords=input.tex_coords;
 return out;
}
@group(0) @binding(0) var t_from: texture_2d<f32>;
@group(0) @binding(1) var t_to: texture_2d<f32>;
@group(0) @binding(2) var s_sampler: sampler;
@group(0) @binding(3) var<uniform> params: Params;
// GL coordinates are bottom-up. Both boundary conversions preserve native orientation.
fn getFromColor(uv: vec2<f32>) -> vec4<f32> {
 return textureSampleLevel(t_from,s_sampler,vec2<f32>(uv.x,1.0-uv.y),0.0);
}
fn getToColor(uv: vec2<f32>) -> vec4<f32> {
 return textureSampleLevel(t_to,s_sampler,vec2<f32>(uv.x,1.0-uv.y),0.0);
}
'''

def parameters(source):
    out=[]; previous=0
    for m in re.finditer(r'uniform\s+(\w+)\s+(\w+)\s*(?:/\*\s*=\s*(.*?)\*/\s*)?;[^\n]*',source):
        t,n,inline=m.group(1,2,3)
        if t=='sampler2D': continue
        default=inline or re.search(r'//\s*=\s*(.*)',m.group())[1]
        default=default.split(';')[0].strip()
        if t=='bool': val=default=='true'
        elif width(t)>1:
            values=[float(x) for x in re.findall(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?',default[default.index('(')+1:default.rindex(')')])]
            val=values*width(t) if len(values)==1 else values
            if t.startswith('ivec'): val=[int(v) for v in val]
        else: val=int(default) if t=='int' else float(default)
        item={'name':n,'type':t.replace('ivec','vec'),'glsl_type':t,'source_type':t,'default':val}
        range_match=re.search(r'@range\(\s*([-+\d.]+)\s*,\s*([-+\d.]+)',source[previous:m.start()])
        if range_match: item.update(min=float(range_match[1]),max=float(range_match[2]))
        previous=m.end(); out.append(item)
    return out

def main():
    ap=argparse.ArgumentParser(description=__doc__); ap.add_argument('--only',nargs='*'); args=ap.parse_args()
    vendor=ROOT/'vendor/gl-transitions'
    observed=subprocess.run(['git','-C',str(vendor),'rev-parse','HEAD'],check=True,capture_output=True,text=True).stdout.strip()
    dirty=subprocess.run(['git','-C',str(vendor),'status','--porcelain'],check=True,capture_output=True,text=True).stdout.strip()
    if observed!=COMMIT or dirty: raise ValueError('Pinned upstream checkout is changed or dirty; refusing to misattribute ports.')
    dest=ROOT/'resources/gl-transitions'; (dest/'wgsl').mkdir(parents=True,exist_ok=True); (dest/'originals').mkdir(exist_ok=True)
    shutil.copyfile(ROOT/'vendor/gl-transitions/LICENSE',dest/'LICENSE')
    old={x['id']:x for x in json.loads((dest/'catalog.json').read_text())['effects']} if (dest/'catalog.json').exists() else {}
    entries=[]
    for path in sorted((ROOT/'vendor/gl-transitions/transitions').glob('*.glsl'),key=lambda p:p.stem.lower()):
        eid='gl.'+path.stem
        if args.only and path.stem not in args.only and eid in old: entries.append(old[eid]); continue
        source=path.read_text(encoding='utf-8'); shutil.copyfile(path,dest/'originals'/path.name)
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        license=re.search(r'//\s*License:\s*([^\n]+)',source,re.I)
        authors=re.findall(r'//\s*Author:\s*([^\n]+)',source,re.I)
        entry={'id':eid,'name':path.stem,'source':{'path':path.relative_to(ROOT).as_posix(),'sha256':digest,'commit':COMMIT},'license':license[1].strip() if license else 'MIT','authors':[a.strip() for a in authors], 'parameters':[], 'status':'incomplete'}
        try:
            extra=re.findall(r'uniform\s+sampler2D\s+(\w+)',source)
            entry['texture_inputs']=[{'name':'to','description':'Incoming image or video'}]+[{'name':n,'description':'Additional upstream grayscale map; required', 'kind':'image'} for n in extra]
            entry['sources_min']=entry['sources_max']=2+len(extra)
            params=parameters(source); entry['parameters']=[{k:v for k,v in p.items() if k!='glsl_type'} for p in params]
            parser=Parser(source); ast=parser.program(); shader=Generator(ast,params,parser.structs).generate()
            shader='// Ported from '+path.name+' at '+COMMIT+'\n// Source SHA-256: '+digest+'\n// Original authors: '+', '.join(authors)+'\n// License: '+entry['license']+'; full original notices in ../originals/'+path.name+' and ../LICENSE\n'+shader
            output=dest/'wgsl'/(path.stem+'.wgsl'); output.write_text(shader,encoding='utf-8',newline='\n')
            entry['implementation']={'kind':'customShader','path':output.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
            entry['reason']='Generated typed port; native rendering verification pending.'
        except Exception as exc:
            entry['reason']=str(exc)
            if str(exc).startswith('Requires third texture:'): entry['status']='unsupported'; entry['reason']='External auxiliary sampler has no resource binding in the two-texture contract. '+str(exc)
        entries.append(entry)
    (dest/'catalog.json').write_text(json.dumps({'schema_version':1,'upstream_commit':COMMIT,'effects':entries},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'total':len(entries),'ports':sum('implementation' in e for e in entries),'issues':{e['id']:e['reason'] for e in entries if 'implementation' not in e}},indent=2))
if __name__=='__main__': main()
