ec_requires +Int +VoteCore.

direct VotingPort {
  in client@start(p0 : port, p1 : port, p2 : port, p3 : port)
  in voter@vote(sid : int, view : int, phase : int, block : int)
  out ready@client
  out result(accepted : bool, count : int, qc : bool)@voter
}
direct Voting { D : VotingPort }

functionality VoteReal implements Voting {
  party Collector serves Voting.D {
    initial state Init {
      match message with
      | client@Voting.D.start(p0,p1,p2,p3) => {
          if (envport p0 /\ envport p1 /\ envport p2 /\ envport p3 /\
              p0 <> p1 /\ p0 <> p2 /\ p0 <> p3 /\ p1 <> p2 /\ p1 <> p3 /\ p2 <> p3) {
            send Voting.D.ready@client and transition Collect(p0,p1,p2,p3,empty,12).
          } else { fail. }
        }
      | * => { fail. }
      end
    }
    state Collect(p0 : port,p1 : port,p2 : port,p3 : port,s : votes,fuel : int) {
      var i : int;
      var s2 : votes;
      var accepted : bool;
      match message with
      | voter@Voting.D.vote(sid,view,phase,block) => {
          if (has_fuel fuel) {
            if (voter = p0) { i <- 0; }
            elif (voter = p1) { i <- 1; }
            elif (voter = p2) { i <- 2; }
            elif (voter = p3) { i <- 3; }
            else { i <- unknown; }
            accepted <- valid i sid view phase block /\ !seen s i;
            s2 <- step s i sid view phase block;
            send Voting.D.result(accepted,count s2,qc s2)@voter
              and transition Collect(p0,p1,p2,p3,s2,decrease fuel).
          } else { fail. }
        }
      | * => { fail. }
      end
    }
  }
}

(* Specification wrapper for interpreter comparison; no UC theorem is claimed. *)
adversarial VoteAdv {
  out initialized
  in resume
}
functionality VoteIdeal implements Voting VoteAdv {
  initial state Init {
    match message with
    | client@Voting.D.start(p0,p1,p2,p3) => {
      if (envport p0 /\ envport p1 /\ envport p2 /\ envport p3 /\
          p0 <> p1 /\ p0 <> p2 /\ p0 <> p3 /\ p1 <> p2 /\ p1 <> p3 /\ p2 <> p3) {
        send VoteAdv.initialized and transition Waiting(client,p0,p1,p2,p3).
      } else { fail. }
    }
    | * => { fail. }
    end
  }
  state Waiting(client : port,p0 : port,p1 : port,p2 : port,p3 : port) {
    match message with
    | VoteAdv.resume => {
      send Voting.D.ready@client and transition Collect(p0,p1,p2,p3,empty,12).
    }
    | * => { fail. }
    end
  }
    state Collect(p0 : port,p1 : port,p2 : port,p3 : port,s : votes,fuel : int) {
      var i : int;
      var s2 : votes;
      var accepted : bool;
      match message with
      | voter@Voting.D.vote(sid,view,phase,block) => {
          if (has_fuel fuel) {
            if (voter = p0) { i <- 0; }
            elif (voter = p1) { i <- 1; }
            elif (voter = p2) { i <- 2; }
            elif (voter = p3) { i <- 3; }
            else { i <- unknown; }
            accepted <- valid i sid view phase block /\ !seen s i;
            s2 <- step s i sid view phase block;
            send Voting.D.result(accepted,count s2,qc s2)@voter
              and transition Collect(p0,p1,p2,p3,s2,decrease fuel).
          } else { fail. }
        }
      | * => { fail. }
      end
    }

}
simulator VoteSim uses VoteAdv simulates VoteReal {
  initial state Init {
    match message with
    | VoteAdv.initialized => { send VoteAdv.resume and transition Final. }
    end
  }
  state Final {
    match message with
    | * => { fail. }
    end
  }
}
