#define ATS_STALOADFLAG 0
#define ATS_DYNLOADFLAG 0

staload "SATS/queue.sats"
staload "SATS/cycbuf.sats"

assume queue(a:t@ype, n:int, s:int) =
  [w,r:nat | n <= s; w < s; r < s] cycbuf_array(a, n, s, w, r)
  
fun {a:t@ype} cycbuf_insert {l:agz} {s:pos} {n:nat | n < s}
    {w, r: nat | n < s; w < s; r < s} (
    pf: !cycbuf_array(a, n, s, w, r) @ l >> cycbuf_array(a, n+1, s, w', r) @ l |
    p: ptr l, x: a
) : #[w':nat | w' < s] void = let
    val () = p->n := p->n + 1
    val () = p->base.[p->w] := x
  in
    p->w := (p->w + 1) nmod1 p->size
  end

fun {a:t@ype} cycbuf_remove {l:agz} {s,n:pos}
    {w,r:nat | n <= s; w < s; r < s} (
    pf: !cycbuf_array(a, n, s, w, r) @ l >> cycbuf_array(a, n-1, s, w, r') @ l | 
    p: ptr l, x: &a? >> a
) : #[r':nat | r' < s] void = let
    val () = p->n := p->n - 1
    val () = x := p->base.[p->r]
  in
    p->r := (p->r + 1) nmod1 p->size
  end


implement {a} insert (lpf, pf | p , x) =
  cycbuf_insert(pf | p, x)

implement {a} remove (lpf, pf | p , x) = 
  cycbuf_remove(pf | p, x)
  
fun {a:t@ype} cycbuf_is_empty {l:addr} {s, n:nat | n <= s}
    {w,r:nat | w < s; r < s} (
    pf: !cycbuf_array(a,n,s,w,r) @ l | p: ptr l
) : bool(n == 0) = p->n = 0

implement {a} empty (pf | p) = 
  cycbuf_is_empty(pf | p)

fun {a:t@ype} cycbuf_is_full {l:agz} {s:pos}
      {n,w,r:nat | n <= s; w < s; r < s} (
    pf: !cycbuf_array(a,n,s,w,r) @ l | p: ptr l
) : bool(n == s) = p->size = p->n

implement {a} full (pf | p) =
  cycbuf_is_full(pf | p)