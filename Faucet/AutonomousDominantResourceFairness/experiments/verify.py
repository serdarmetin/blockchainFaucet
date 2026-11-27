import json
from fractions import Fraction
import solcx
from web3 import Web3
w=Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))
assert w.is_connected()
accounts=w.eth.accounts
def deploy(version):
    src=f'AutonomousDRF_v_2.1.3_{version}.sol'
    c=next(iter(solcx.compile_files([src],solc_version='0.5.17',optimize=True,optimize_runs=200,evm_version='istanbul').values()))
    receipt=w.eth.wait_for_transaction_receipt(w.eth.contract(abi=c['abi'],bytecode=c['bin']).constructor().transact({'from':accounts[0],'gas':12000000,'gasPrice':0}))
    assert receipt.status==1
    return w.eth.contract(address=receipt.contractAddress,abi=c['abi']),receipt.blockNumber
def tx(fn,account,ok=True):
    r=w.eth.wait_for_transaction_receipt(fn.transact({'from':account,'gas':12000000,'gasPrice':0}))
    assert bool(r.status)==ok,(fn.fn_name,r.status,ok)
    return r.gasUsed
def mine_to(block):
    while w.eth.block_number<block:
        w.provider.make_request('evm_mine',[])
def register(c,n):
    for a in accounts[1:n+1]: tx(c.functions.registerUser(a),accounts[0])
c,b=deploy('corrected')
assert list(c.functions.viewCapacity(0).call())==[1500,1500]
assert list(c.functions.viewCapacity(1).call())==[1500,1500]
register(c,2)
tx(c.functions.demand([3,1]),accounts[1])
tx(c.functions.demand([9,5]),accounts[2])
assert c.functions.viewMaxDominantShare(0).call()==166666666
tx(c.functions.demand([3,1]),accounts[1],False)
mine_to(b+20)
tx(c.functions.demand([1,2]),accounts[1])
tx(c.functions.claim(),accounts[1])
tx(c.functions.claim(),accounts[2])
tx(c.functions.demand([2,1]),accounts[2])
tx(c.functions.claim(),accounts[1],False)
mine_to(b+80)
tx(c.functions.claim(),accounts[1],False)
tx(c.functions.demand([1,1]),accounts[1])
assert c.functions.viewShare().call()==0
print('Functional checks passed')
workloads=[[[3,1],[9,5],[3,5],[6,10],[5,4],[10,8],[2,4],[9,4],[4,6],[5,4]],[[3,5],[1,5],[2,4],[3,7],[6,6],[10,7],[6,5],[7,6],[4,1],[3,8]]]
rows=[]
for version in ['original','corrected']:
    c,b=deploy(version)
    register(c,10)
    for epoch,ds in enumerate(workloads,1):
        cap=list(c.functions.viewCapacity((epoch+1)%2).call())
        dg=[tx(c.functions.demand(d),accounts[i]) for i,d in enumerate(ds,1)]
        # Demand pool may be replenished by first demand transaction only if epoch transitions.
        cap=list(c.functions.viewCapacity((epoch+1)%2).call())
        shares=[max(Fraction(x,y) for x,y in zip(d,cap)) for d in ds]
        h=min(Fraction(cap[r],1)/sum(Fraction(d[r],1)/s for d,s in zip(ds,shares)) for r in range(2))
        for i,(d,s) in enumerate(zip(ds,shares),1):
            before=c.functions.viewBalance(i).call()
            gas=tx(c.functions.claim(),accounts[i])
            after=c.functions.viewBalance(i).call()
            actual=[y-x for x,y in zip(before,after)]
            expected=[int(h/s)*x for x in d]
            rows.append(dict(version=version,epoch=epoch,user=i,demand=d,capacity=cap,actual=actual,expected=expected,demand_gas=dg[i-1],claim_gas=gas))
with open('results.json','w') as f: json.dump(rows,f,indent=2)
print(json.dumps(rows))
