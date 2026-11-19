require import AllCore Int.

(* A fixed quorum of 4 registered, authenticated identities; f = 1. *)
type votes = bool * bool * bool * bool.
op empty : votes = (false, false, false, false).
op bit (b : bool) : int = if b then 1 else 0.
op count (s : votes) : int = bit s.`1 + bit s.`2 + bit s.`3 + bit s.`4.
op member (i : int) : bool = i=0 \/ i=1 \/ i=2 \/ i=3.
op seen (s : votes) (i : int) : bool =
  if i=0 then s.`1 else if i=1 then s.`2 else if i=2 then s.`3 else if i=3 then s.`4 else false.
op add (s : votes) (i : int) : votes =
  if i=0 then (true,s.`2,s.`3,s.`4)
  else if i=1 then (s.`1,true,s.`3,s.`4)
  else if i=2 then (s.`1,s.`2,true,s.`4)
  else if i=3 then (s.`1,s.`2,s.`3,true) else s.
(* Fixed context: sid=1, view=1, Prepare phase=0, block=42. *)
op valid (i sid view phase block : int) : bool =
  member i /\ sid = 1 /\ view = 1 /\ phase = 0 /\ block = 42.
op step (s : votes) (i sid view phase block : int) : votes =
  if valid i sid view phase block then add s i else s.
op qc (s : votes) : bool = 3 <= count s.

op has_fuel (fuel : int) = 0 < fuel.
op decrease (fuel : int) = fuel - 1.
op unknown : int = -1.

lemma count_bounds s : 0 <= count s /\ count s <= 4.
proof. case s => a b c d; case a; case b; case c; case d; by rewrite /count /bit /=. qed.
lemma duplicate_is_noop s i : seen s i => add s i = s.
proof.
case s => a b c d; rewrite /seen /add /=.
case (i=0); case (i=1); case (i=2); case (i=3); case a; case b; case c; case d; done.
qed.
lemma invalid_is_noop s i sid view phase block :
  !valid i sid view phase block => step s i sid view phase block = s.
proof. move => H; by rewrite /step H. qed.
lemma fresh_vote_counts_once s i : member i => !seen s i => count (add s i) = count s + 1.
proof.
case s => a b c d; rewrite /member /seen /count /bit /add /=.
case (i=0); case (i=1); case (i=2); case (i=3); case a; case b; case c; case d; done.
qed.
lemma qc_has_three_distinct s : qc s <=>
 (s.`1 /\ s.`2 /\ s.`3) \/ (s.`1 /\ s.`2 /\ s.`4) \/
 (s.`1 /\ s.`3 /\ s.`4) \/ (s.`2 /\ s.`3 /\ s.`4).
proof. case s => a b c d; case a; case b; case c; case d; by rewrite /qc /count /bit /=. qed.
lemma insufficient_votes_no_qc s : count s < 3 => !qc s.
proof. case s => a b c d; case a; case b; case c; case d; by rewrite /qc /count /bit /=. qed.
lemma quorum_intersection a b : qc a => qc b =>
  2 <= bit (a.`1 /\ b.`1) + bit (a.`2 /\ b.`2) +
       bit (a.`3 /\ b.`3) + bit (a.`4 /\ b.`4).
proof.
case a => a0 a1 a2 a3; case b => b0 b1 b2 b3.
case a0; case a1; case a2; case a3; case b0; case b1; case b2; case b3; by rewrite /qc /count /bit /=.
qed.

(* The count changes exactly when the DSL reports acceptance. *)
lemma step_count s i sid view phase block :
  count (step s i sid view phase block) =
    count s + bit (valid i sid view phase block /\ !seen s i).
proof.
case (valid i sid view phase block) => Hv; rewrite /step Hv /=.
- case (seen s i) => Hs; rewrite /bit /=.
  + by rewrite (duplicate_is_noop s i Hs).
  + apply fresh_vote_counts_once => //.
    by move: Hv; rewrite /valid => -[].
- by rewrite /bit.
qed.

(* Executable EasyCrypt collector using the exact transition used by the DSL. *)
module Collector = {
  var voters : votes
  proc init() : unit = { voters <- empty; }
  proc vote(i sid view phase block : int) : int * bool = {
    voters <- step voters i sid view phase block;
    return (count voters, qc voters);
  }
}.
lemma vote_threshold i0 sid0 v0 p0 b0 :
 hoare [Collector.vote :
   i=i0 /\ sid=sid0 /\ view=v0 /\ phase=p0 /\ block=b0
   ==> res.`2 <=> 3 <= res.`1].
proof. proc; auto; by rewrite /qc. qed.
lemma vote_duplicate s i0 : seen s i0 =>
 hoare [Collector.vote : Collector.voters=s /\ i=i0
   ==> Collector.voters=s].
proof.
move => H; proc; auto.
move => &m [Hs Hi].
rewrite Hs Hi /step.
case (valid i0 sid{m} view{m} phase{m} block{m}); by rewrite ?(duplicate_is_noop s i0 H).
qed.
lemma vote_lossless : islossless Collector.vote.
proof. proc; auto. qed.

(* Proved unfolding rules for the EasyUC interpreter. *)
lemma eval_empty  : empty = ((false, false, false, false)).
proof. by rewrite /empty. qed.
lemma eval_bit b : bit b = (if b then 1 else 0).
proof. by rewrite /bit. qed.
lemma eval_count s : count s = (bit s.`1 + bit s.`2 + bit s.`3 + bit s.`4).
proof. by rewrite /count. qed.
lemma eval_member i : member i = (i = 0 \/ i = 1 \/ i = 2 \/ i = 3).
proof. by rewrite /member. qed.
lemma eval_seen s i : seen s i = (if i = 0 then s.`1 else if i = 1 then s.`2 else if i = 2 then s.`3 else if i = 3 then s.`4 else false).
proof. by rewrite /seen. qed.
lemma eval_add s i : add s i = (if i = 0 then (true,s.`2,s.`3,s.`4) else if i = 1 then (s.`1,true,s.`3,s.`4) else if i = 2 then (s.`1,s.`2,true,s.`4) else if i = 3 then (s.`1,s.`2,s.`3,true) else s).
proof. by rewrite /add. qed.
lemma eval_valid i sid view phase block : valid i sid view phase block = (member i /\ sid = 1 /\ view = 1 /\ phase = 0 /\ block = 42).
proof. by rewrite /valid. qed.
lemma eval_step s i sid view phase block : step s i sid view phase block = (if valid i sid view phase block then add s i else s).
proof. by rewrite /step. qed.
lemma eval_qc s : qc s = (3 <= count s).
proof. by rewrite /qc. qed.
lemma eval_has_fuel fuel : has_fuel fuel = (0 < fuel).
proof. by rewrite /has_fuel. qed.
lemma eval_decrease fuel : decrease fuel = (fuel - 1).
proof. by rewrite /decrease. qed.
lemma eval_unknown  : unknown = (-1).
proof. by rewrite /unknown. qed.

hint rewrite vote_eval :
  eval_empty eval_bit eval_count eval_member eval_seen eval_add eval_valid eval_step eval_qc eval_has_fuel eval_decrease eval_unknown.
