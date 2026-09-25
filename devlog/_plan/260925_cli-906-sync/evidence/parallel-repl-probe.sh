#!/bin/bash
# wp2 parallel REPL probe — read-only, public pages only. Evidence -> $1
A="$HOME/.local/bin/aside"
OUT="${1:?out dir}"; mkdir -p "$OUT"
DL() { /usr/bin/perl -e 'alarm shift; exec @ARGV' 110 "$A" --account u0 --host local repl "$1"; }
ts() { /usr/bin/perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }
URLS=(https://example.com https://example.org https://www.iana.org/help/example-domains https://example.net)
# each job: open, snapshot, report own targetId + session tab ids, close in finally
job() { echo "const t$2 = await openTab('$1'); console.log('OPEN$2', t$2.targetId); try { const s$2 = await snapshot(t$2, {interactive:true}); console.log('JOB$2', JSON.stringify({title: await t$2.title(), url: t$2.url(), own: t$2.targetId, session: tabs.map(x => x.targetId), treeLines: s$2.tree.split('\\n').length})); } finally { await closeTab(t$2); }"; }
lsids() { echo "const l$1 = await listBrowserTabs(); console.log('$1', JSON.stringify(l$1.map(x => [x.targetId, x.url])));"; }

DL "$(lsids BASE)" > "$OUT/00_base.txt" 2>&1; echo "exit=$?" >> "$OUT/00_base.txt"

t0=$(ts); for i in 0 1 2 3; do DL "$(job ${URLS[$i]} $i)" > "$OUT/10_seq_$i.txt" 2>&1; echo "exit=$?" >> "$OUT/10_seq_$i.txt"; done; t1=$(ts)
echo "seq_wall $(echo "$t1 - $t0" | bc)" > "$OUT/timing.txt"

t0=$(ts); for i in 0 1 2 3; do ( DL "$(job ${URLS[$i]} $i)" > "$OUT/20_par_$i.txt" 2>&1; echo "exit=$?" >> "$OUT/20_par_$i.txt" ) & done; wait; t1=$(ts)
echo "par_wall $(echo "$t1 - $t0" | bc)" >> "$OUT/timing.txt"

t0=$(ts); for i in 0 1 2 3 4 5 6 7; do ( DL "$(job ${URLS[$((i%4))]} $i)" > "$OUT/25_par8_$i.txt" 2>&1; echo "exit=$?" >> "$OUT/25_par8_$i.txt" ) & done; wait; t1=$(ts)
echo "par8_wall $(echo "$t1 - $t0" | bc)" >> "$OUT/timing.txt"

t0=$(ts)
DL "const urls = $(printf "'%s'," "${URLS[@]}" | sed 's/^/[/;s/,$/]/'); const r30 = await Promise.allSettled(urls.map(u => openTab(u))); const pages = r30.filter(x => x.status === 'fulfilled').map(x => x.value); try { const titles = await Promise.all(pages.map(p => p.title())); console.log('PALL', JSON.stringify({settled: r30.map(x => x.status), titles, ids: pages.map(p => p.targetId), session: tabs.length, pageNow: page.targetId})); } finally { for (const p of pages) await closeTab(p); }" > "$OUT/30_promise_all.txt" 2>&1; echo "exit=$?" >> "$OUT/30_promise_all.txt"
t1=$(ts); echo "pall_wall $(echo "$t1 - $t0" | bc)" >> "$OUT/timing.txt"

( DL "const ia = await openTab('https://example.com'); try { console.log('A0', Date.now(), JSON.stringify({own: ia.targetId, page: page.targetId, session: tabs.map(x => x.targetId)})); await sleep(8000); console.log('A1', Date.now(), JSON.stringify({page: page.targetId, session: tabs.map(x => x.targetId)})); } finally { await closeTab(ia); }" > "$OUT/40_iso_a.txt" 2>&1; echo "exit=$?" >> "$OUT/40_iso_a.txt" ) &
sleep 3
DL "const ib = await openTab('https://example.org'); try { console.log('B0', Date.now(), JSON.stringify({own: ib.targetId, page: page.targetId, session: tabs.map(x => x.targetId)})); } finally { await closeTab(ib); }" > "$OUT/40_iso_b.txt" 2>&1; echo "exit=$?" >> "$OUT/40_iso_b.txt"
wait

DL "$(lsids AFTER)" > "$OUT/90_after.txt" 2>&1; echo "exit=$?" >> "$OUT/90_after.txt"
echo done
