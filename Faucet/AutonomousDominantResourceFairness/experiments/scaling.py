import json,sys,re,random
from fractions import Fraction
from pathlib import Path
from web3 import Web3
import solcx
n,m,rounds=map(int,sys.argv[1:])
w=Web3(Web3.HTTPProvider('http://127.0.0.1:8545',request_kwargs={'timeout':120}))
accounts=w.eth.accounts
assert len(accounts)>=n+1
rng=random.Random(20261126)
workloads=[[[rng.randint(1,10) for _ in range(m)] for _ in range(n)] for _ in range(rounds)]
rows=[]
for version in ['original','original_aligned','corrected']:
    source=Path('AutonomousDRF_v_2.1.3_'+('corrected' if version=='corrected' else 'original')+'.sol').read_text()
    source=re.sub(r'(constant nore = )\d+',rf'\g<1>{m}',source)
    source=re.sub(r'(constant userQuota = )\d+',rf'\g<1>{n}',source)
    if version=='original_aligned':
        old='r[0][i] = 150 * userQuota;'
        lines=source.splitlines(keepends=True)
        matches=[i for i,line in enumerate(lines) if line.strip()==old]
        assert len(matches)==2, matches
        lines[matches[1]]=lines[matches[1]].replace(old,'r[1][i] = 150 * userQuota;')
        source=''.join(lines)
    c=next(iter(solcx.compile_source(source,solc_version='0.5.17',optimize=True,optimize_runs=200,evm_version='istanbul').values()))
    def receipt(fn,a):
        r=w.eth.wait_for_transaction_receipt(fn.transact({'from':a,'gas':12000000,'gasPrice':0}))
        assert r.status==1,(version,fn,r.blockNumber)
        return r
    r=receipt(w.eth.contract(abi=c['abi'],bytecode=c['bin']).constructor(),accounts[0])
    b=r.blockNumber
    f=w.eth.contract(address=r.contractAddress,abi=c['abi']).functions
    for a in accounts[1:n+1]: receipt(f.registerUser(a),accounts[0])
    for e,ds in enumerate(workloads,1):
        dg=[receipt(f.demand(d),accounts[i]).gasUsed for i,d in enumerate(ds,1)]
        cap=list(f.viewCapacity((e+1)%2).call())
        shares=[max(Fraction(x,y) for x,y in zip(d,cap)) for d in ds]
        h=min(Fraction(cap[j],1)/sum(Fraction(d[j],1)/s for d,s in zip(ds,shares)) for j in range(m))
        for i,(d,s) in enumerate(zip(ds,shares),1):
            before=f.viewBalance(i).call()
            cg=receipt(f.claim(),accounts[i]).gasUsed
            after=f.viewBalance(i).call()
            actual=[y-x for x,y in zip(before,after)]
            expected=[int(h/s)*x for x in d]
            rows.append(dict(version=version,epoch=e,user=i,demand=d,capacity=cap,actual=actual,expected=expected,demand_gas=dg[i-1],claim_gas=cg))
    Path('results.json').write_text(json.dumps(rows))
    print(version,'matches',sum(x['actual']==x['expected'] for x in rows if x['version']==version),'of',n*rounds,flush=True)
Path('results.json').write_text(json.dumps(rows))
for v in ['original','original_aligned','corrected']:
    a=[x for x in rows if x['version']==v]
    print(json.dumps(dict(version=v,users=n,resources=m,rounds=rounds,matches=sum(x['actual']==x['expected'] for x in a),mean_demand=sum(x['demand_gas'] for x in a)/len(a),mean_claim=sum(x['claim_gas'] for x in a)/len(a))),flush=True)
