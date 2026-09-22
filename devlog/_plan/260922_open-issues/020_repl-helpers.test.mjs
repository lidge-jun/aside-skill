import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
const source = await readFile(new URL('../../../aside-jun/scripts/repl-helpers.js', import.meta.url), 'utf8');
function fixture({count=1, box={x:8,y:8,width:120,height:60}, viewport={width:800,height:600}, failure}={}) {
  const dirs = new Set(); const calls=[]; const bytes=Buffer.from('png-proof');
  const fs={mkdir:async (p,o)=>{assert.equal(o.recursive,true);dirs.add(p);}};
  const api=vm.runInNewContext(source,{fs});
  const locator={count:async()=>count,scrollIntoViewIfNeeded:async()=>{calls.push('scroll');},boundingBox:async()=>box};
  const page={locator:()=>locator,viewportSize:()=>viewport,screenshot:async opts=>{if(failure)throw failure;calls.push(opts);return bytes;}};
  return {api,dirs,calls,bytes,locator,page};
}
test('preparation creates both missing parents and is idempotent',async()=>{
 const f=fixture();await f.api.prepareSessionDirs();await f.api.prepareSessionDirs();assert.deepEqual([...f.dirs].sort(),['./artifacts','./tmp']);
});
test('element capture saves the full viewport source and prepares output dirs',async()=>{
 const f=fixture();assert.equal((await f.api.captureElementSource(f.page,"#sample",{path:'artifacts/capture.png'})).cropped,false);
 assert.equal(f.calls[0],'scroll');assert.equal(f.calls[1].type,'png');assert.equal(f.calls[1].clip,undefined);assert.equal(f.calls[1].fullPage,false);assert.equal(f.calls[1].path,'./artifacts/capture.png');assert.equal(f.dirs.size,2);
});
test('missing source path refuses before writes',async()=>{const f=fixture();await assert.rejects(f.api.captureElementSource(f.page,"#sample"));assert.equal(f.dirs.size,0);});
test('missing, ambiguous, hidden and out-of-viewport targets fail before capture',async()=>{
 for(const options of [{count:0},{count:2},{box:null},{box:{x:-1,y:0,width:1,height:1}},{box:{x:0,y:0,width:Infinity,height:1}},{box:{x:0,y:0,width:0,height:1}},{viewport:{width:10,height:10}}]){
  const f=fixture(options);await assert.rejects(f.api.captureElementSource(f.page,"#sample",{path:"artifacts/source.png"}));assert.equal(f.calls.some(x=>typeof x==='object'),false);assert.equal(f.dirs.size,0);
 }
});
test('paths and unsupported options fail before any page or filesystem effects',async()=>{
 for(const path of ['/tmp/capture.png','../capture.png','./artifacts/../capture.png','C:\\tmp\\capture.png','./artifacts/nested/capture.png','https://example.com/x.png','artifacts/a.png\n']){
  const f=fixture();await assert.rejects(f.api.captureElementSource(f.page,"#sample",{path}));assert.equal(f.calls.length,0);assert.equal(f.dirs.size,0);
 }
 const f=fixture();await assert.rejects(f.api.captureElementSource(f.page,"#sample",{fullPage:true}));
});
test('unrelated screenshot and mkdir errors propagate unchanged',async()=>{
 const original=new Error('denied by actual platform');const f=fixture({failure:original});await assert.rejects(f.api.captureElementSource(f.page,"#sample",{path:"artifacts/source.png"}),e=>e===original);
 const api=vm.runInNewContext(source,{fs:{mkdir:async()=>{throw original;}}});await assert.rejects(api.prepareSessionDirs(),e=>e===original);
});

test('invalid page fails without directory writes',async()=>{const f=fixture();await assert.rejects(f.api.captureElementSource({},"#sample",{path:"artifacts/source.png"}));assert.equal(f.dirs.size,0);});
