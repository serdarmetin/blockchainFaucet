import glob,zipfile,json,sys
from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
out=Path(__file__).parent
rows=[]
for p in glob.glob(str(Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')/'github-actions-artifact-*.zip')):
 with zipfile.ZipFile(p) as z: a=json.loads(z.read(z.namelist()[0]))
 d=pd.DataFrame([x for x in a if x['version']=='corrected']); n=int(d.user.max()); m=len(a[0]['demand'])
 assert len(d)==10*n and all(x==y for x,y in zip(d.actual,d.expected))
 for e,g in d.groupby('epoch'):
  assert len(g)==n and g.claim_transition.sum()==1 and not g.demand_transition.any()
  c=g.loc[~g.claim_transition,'claim_gas'].mean(); t=g.loc[g.claim_transition,'claim_gas'].iloc[0]
  rows.append(dict(users=n,resources=m,round=e,demand=g.demand_gas.mean(),ordinary=c,transition=t,overhead=t-c,claim=g.claim_gas.mean()))
f=pd.DataFrame(rows).sort_values(['users','resources','round']); assert len(f)==100
f.to_csv(out/'all_rounds.csv',index=False); s=f[f['round']==3]; s.to_csv(out/'round3.csv',index=False)
r=s[s.users==10]; u=s[s.resources==10]; fits=[]
for name,df,x,ys in [('demand_resources',r,'resources',['demand']),('claim_resources',r,'resources',['ordinary','transition','claim']),('epoch_update_overhead',r,'resources',['overhead']),('user_scaling',u,'users',['demand','ordinary','transition','claim'])]:
 fig,ax=plt.subplots(figsize=(7,4.3)); labels={'demand':'Demand','ordinary':'Ordinary claim','transition':'Epoch-updating claim','claim':'Mean claim','overhead':'Incremental gas cost'}
 for y in ys:
  ax.plot(df[x],df[y],'o-',label=labels[y])
  if x=='resources':
   a,b=np.polyfit(df[x],df[y],1); pred=a*df[x]+b; r2=1-sum((df[y]-pred)**2)/sum((df[y]-df[y].mean())**2); fits.append(dict(series=y,slope=a,intercept=b,r2=r2))
 if x=='users': ax.set_xscale('log'); ax.set_xticks([10,100,1000],['10','100','1,000'])
 ax.set_xlabel('Number of '+x); ax.set_ylabel('Gas cost'); ax.set_ylim(bottom=0); ax.ticklabel_format(axis='y',style='plain'); ax.grid(alpha=.2); ax.legend(); fig.tight_layout()
 for ext in ['png','svg']: fig.savefig(out/f'{name}.{ext}',dpi=300)
 plt.close(fig)
pd.DataFrame(fits).to_csv(out/'regressions.csv',index=False)
print(s.to_string(index=False)); print(pd.DataFrame(fits).to_string(index=False))
