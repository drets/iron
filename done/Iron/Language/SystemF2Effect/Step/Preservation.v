
Require Export Iron.Language.SystemF2Effect.Step.TypeC.
Require Export Iron.Language.SystemF2Effect.Type.Operator.FreeTT.
Require Export Iron.Language.SystemF2Effect.Store.LiveS.
Require Export Iron.Language.SystemF2Effect.Store.LiveE.


(* When a well typed expression transitions to the next state
   then its type is preserved. *)
Theorem preservation
 :  forall se sp sp' ss ss' fs fs' x x' t e
 ,  WfFS   se sp ss  fs
 -> LiveS ss fs -> LiveE  fs e
 -> TYPEC  nil nil se sp fs  x   t  e    
 -> STEPF  ss  sp  fs x  ss' sp' fs' x'   
 -> (exists se' e'
    ,  extends se' se
    /\ WfFS  se' sp' ss' fs'
    /\ LiveS ss' fs'    
    /\ LiveE fs' e'
    /\ SubsVisibleT  nil sp' sp  e  e'
    /\ TYPEC nil nil se' sp' fs' x' t e').
Proof.
 intros se sp sp' ss ss' fs fs' x x' t e.
 intros HH HLS HLE HC HS. 
 gen t e.
 induction HS; intros.


 (*********************************************************)
 (* Pure evaluation. *)
 Case "SfStep". 
 { inverts_typec. 
   exists se. 
   exists e.
   rip.

   (* Original effect visibly subsumes effect of result. *)
   - apply subsVisibleT_refl.
     eauto.

   (* Resulting configuration is well typed. *)
   - eapply TcExp; eauto.
     eapply stepp_preservation; eauto.
     inverts HH. rip.
 }


 (*********************************************************)
 (* Push let context. *)
 Case "SfLetPush".
 { exists se.
   exists e.
   rip. 

   (* Frame stack with new FLet frame is well formed. *)
   - unfold WfFS in *. 
     unfold STOREP in *. rip.
     eapply H3.
     + inverts H. nope. auto.
     + inverts H. nope. unfold STOREP in *. firstorder.
     + inverts H. nope. unfold STOREP in *. firstorder.
    
   (* All store bindings mentioned by frame stack are still live. *)
   - eapply liveS_push_fLet; auto.

   (* Original effect visibly subsumes effect of result. *)
   - eapply subsVisibleT_refl. 
     inverts HC; eauto.

   (* Resulting configuation is well typed. *)
   - inverts HC.
     inverts H0.
     eapply TcExp 
      with (t1 := t) (e1 := e0) (e2 := TSum e3 e2).
      + eapply EqTrans.
         eapply EqSumAssoc; eauto.
         auto.
      + auto.
      + eapply TfConsLet; eauto.
 }


 (*********************************************************)
 (* Pop let context and substitute. *)
 Case "SfLetPop".
 { exists se.
   exists e.
   rip.

   (* Store is still well formed. *)
   - unfold WfFS in *.
     rip; unfold STOREP in *; firstorder.  

   (* After popping top FLet frame, 
      all store bindings mentioned by frame stack are still live. *)
   - eapply liveS_pop; eauto.

   (* After popping top FLet frame, effects of result are still 
      to live regions. *)
   - eapply liveE_pop_flet; eauto.

   (* Original effect visibly subsumes effect of result. *)
   - eapply subsVisibleT_refl.
     inverts HC; eauto.

   (* Resulting configuration is well typed. *)
   - inverts HC.
     inverts H1.
     eapply TcExp  
      with (t1 := t3) (e1 := e0) (e2 := e3).
      + inverts H0.
        subst.
        eapply EqTrans.
        * eapply equivT_sum_left. eauto.
          have (KindT nil sp e0 KEffect).
          have (KindT nil sp e3 KEffect).
          eauto.
        * auto.
      + eapply subst_val_exp. 
        * eauto.
        * inverts H0. auto.
      + eauto.
 } 


 (*********************************************************)
 (* Create a private region. *)
 Case "SfPrivatePush".
 { inverts_typec.
   set (r := TRgn p).
   exists se.
   exists (TSum (substTT 0 r e0) (substTT 0 r e2)).

   have (sumkind KEffect).

   have (KindT (nil :> KRegion) sp e0 KEffect).

   have (KindT nil sp e1 KEffect)
    by  (eapply equivT_kind_left; eauto).
   have (ClosedT e1).

   have (KindT nil sp e2 KEffect)
    by  (eapply equivT_kind_left; eauto).
   have (ClosedT e2).

   rip.

   (* All store bindings mentioned by resulting frame stack
      are still live. *)
   - inverts HH. rip.
     subst p.
     eapply liveS_push_fPriv; eauto.

   (* Resulting effect is to live regions. *)
   - eapply liveE_sum_above.
     + have HLL: (liftTT 1 0 e1 = maskOnVarT 0 e0)
        by  (eapply lowerTT_some_liftTT; eauto).
       rrwrite (liftTT 1 0 e1 = e1) in HLL.

       have (SubsT nil sp e e1 KEffect) 
        by  (eapply EqSym in H0; eauto).

       have (LiveE fs e1).

       have HLW: (LiveE (fs :> FPriv p) e1).
       rewrite HLL in HLW.

       have HL0: (LiveE (fs :> FPriv p) e0) 
        by (eapply liveE_maskOnVarT; eauto).

       eapply liveE_phase_change; eauto.

     + have (SubsT nil sp e e2 KEffect)
        by  (eapply EqSym in H0; eauto).

       have (LiveE fs e2).
       have (LiveE (fs :> FPriv p) e2).
       rrwrite (substTT 0 r e2 = e2); auto.
       
   (* Effect of result is subsumed by previous. *)
   - rrwrite ( TSum (substTT 0 r e0) (substTT 0 r e2)
             = substTT 0 r (TSum e0 e2)).
     have (ClosedT e).
     have HE: (substTT 0 r e = e). rewrite <- HE. clear HE.

     simpl.
     set (sp' := SRegion p <: sp).
     assert (SubsVisibleT nil sp' sp (substTT 0 r e) (substTT 0 r e0)).
     { have HE: (EquivT       nil sp' e (TSum e1 e2) KEffect)
        by (subst sp'; eauto).

       have HS: (SubsT        nil sp' e e1 KEffect)
        by (subst sp'; eauto).
      
       apply lowerTT_some_liftTT in H5.

       assert   (SubsVisibleT nil sp' sp (liftTT 1 0 e) (liftTT 1 0 e1)) as HV.
        rrwrite (liftTT 1 0 e  = e).
        rrwrite (liftTT 1 0 e1 = e1).
        eapply subsT_subsVisibleT.
        auto.
       rewrite H5 in HV.

       rrwrite (liftTT  1 0 e = e) in HV.
       rrwrite (substTT 0 r e = e).
       eapply subsVisibleT_mask; eauto.
     }

     assert (SubsVisibleT nil sp' sp (substTT 0 r e) (substTT 0 r e2)).
     { rrwrite (substTT 0 r e  = e).
       rrwrite (substTT 0 r e2 = e2).

       have HE: (EquivT nil sp' e (TSum e1 e2) KEffect)
        by (subst sp'; eauto).
        
       eapply SbEquiv in HE.
       eapply SbSumAboveRight in HE.
       eapply subsT_subsVisibleT. auto. auto.
     }
 
     unfold SubsVisibleT.
      simpl.
      apply SbSumAbove; auto.

   (* Result expression is well typed. *)
   - rrwrite (substTT 0 r e2 = e2).
     eapply TcExp 
       with (sp := SRegion p <: sp) 
            (t1 := substTT 0 r t0)
            (e1 := substTT 0 r e0)
            (e2 := substTT 0 r e2); auto.

     (* Type of result is equivlent to before *)
     + rrwrite (substTT 0 r e2 = e2).
       eapply EqRefl.
        eapply KiSum; auto.
         * eapply subst_type_type. eauto.
           subst r. eauto.

     (* Type is preserved after substituting region handle. *)
     + have HTE: (nil = substTE 0 r nil).
       rewrite HTE.

       have HSE: (se  = substTE 0 r se)
        by (inverts HH; symmetry; auto).
       rewrite HSE.

       eapply subst_type_exp with (k2 := KRegion).
       * rrwrite (liftTE 0 nil = nil).
         rrwrite (liftTE 0 se  = se) 
          by (inverts HH; auto).
         auto.
       * subst r. auto.
         eapply KiRgn.
         rrwrite (SRegion p <: sp = sp ++ (nil :> SRegion p)).
         eapply in_app_right. snorm.

     (* New frame stack is well typed. *)
     + eapply TfConsPriv.

       (* New region handle is not in the existing frame stack. *)
       * unfold not. intros.

         have (In (SRegion p) sp)
          by (eapply wfFS_fpriv_sregion; eauto).

         have (not (In (SRegion (allocRegion sp)) sp)).
         have (In (SRegion p) sp).
         rewrite H in H14. tauto.

       (* Effect of frame stack is still to live regions *)
       * rrwrite (substTT 0 r e2 = e2).
         have    (SubsT nil sp e e2 KEffect) 
          by     (eapply EqSym in H0; eauto).
         eapply  liveE_subsT; eauto.

       (* Frame stack is well typed after substituting region handle.
          The initial type and effect are closed, so substituting
          the region handle into them doesn't do anything. *)
       * assert (ClosedT t0).
         { have HK: (KindT  (nil :> KRegion) sp t0 KData).
           eapply kind_wfT in HK.
           simpl in HK.

           have (freeTT 0 t0 = false) 
            by (eapply lowerTT_freeT; eauto).
           eapply freeTT_wfT_drop; eauto.
         }

         rrwrite (substTT 0 r t0 = t0).
         rrwrite (substTT 0 r e2 = e2).
         rrwrite (t1 = t0) 
          by (eapply lowerTT_closedT; eauto).
         eauto.
 }


 (*********************************************************)
 (* Pop a private region from the frame stack. *)
 Case "SfPrivatePop".
 { inverts_typec.

   (* We can only pop if there is at least on region in the store. *)
   destruct sp.

   (* No regions in store. *)
   - inverts HH. rip. 
     unfold STOREP in *. rip.
     spec H3 p.
     have (In (FPriv p) (fs :> FPriv p)).
      rip. nope.

   (* At least one region in store. *)
   - destruct s.
     exists se.
     exists e2.
     rip.
     (* Frame stack is still well formed after popping the top FUse frame *)
     + eapply wfFS_region_deallocate; auto.

     (* After popping top FUse,
        all store bindings mentioned by frame stack are still live. *)
     + eapply liveS_deallocate; eauto.

     (* New effect subsumes old one. *)
     + eapply subsT_subsVisibleT.
       have HE: (EquivT nil (sp :> SRegion n) e2 e KEffect).
       eauto.

     (* Resulting configuation is well typed. *)
     + eapply TcExp 
         with (sp := sp :> SRegion n)
              (e1 := TBot KEffect)
              (e2 := e2); eauto.

       eapply EqSym; eauto.
 }


 (*********************************************************)
 (* Push an extend frame on the stack. *)
 Case "SfExtendPush".
 { inverts_typec.
   set (r1 := TRgn p1).
   set (r2 := TRgn p2).
   exists se.
   exists (TSum (substTT 0 r2 e0) (TSum e2 (TAlloc r1))).
   rip.
   
   (* Updated store is well formed. *)
   - eapply wfFS_region_ext; auto.
     inverts H10. auto.

   (* Updated store is live relative to frame stack. *)
   - eapply liveS_push_fExt; auto.

   (* Frame stack is live relative to effect. *)
   - admit.

   (* Effect of result is subsumed by previous. *)
   - admit. (* ok *)

   (* Resulting state is well typed. *)
   - eapply TcExp
       with (e1 := substTT 0 r2 e0)
            (e2 := TSum e2 (TAlloc r1))
            (t1 := substTT 0 r2 t0).
     (* Equivalence of result effect *)
     + eapply EqRefl.
       eapply KiSum; auto.
       * subst r2.
         have (KindT (nil :> KRegion) sp                 e0 KEffect).
         have (KindT (nil :> KRegion) (SRegion p2 <: sp) e0 KEffect).
         have (KindT nil (SRegion p2 <: sp) (TRgn p2) KRegion).
         eapply subst_type_type. eauto. eauto.
       * apply equivT_kind_left in H0.
         inverts_kind. subst r1.
         eapply KiSum; auto.
         eapply KiCon1. snorm. eauto.
   
     (* Expression with new region subst is well typed. *)
     + rgwrite (nil = substTE 0 r2 nil).
       rgwrite (se  = substTE 0 r2 se)
        by (inverts HH; symmetry; auto).

       eapply subst_type_exp.
       * eapply typex_stprops_snoc.
         rgwrite (nil = liftTE 0 nil).
         rgwrite (se  = liftTE 0 se)
          by (inverts HH; symmetry; auto).
         eauto.
       * subst r2. eauto.

     (* Extended frame stack is well typed. *)
     + have (KindT (nil :> KRegion) sp t0 KData).
       have (not (In (SRegion p2) sp))
        by (subst p2; auto).
       eapply TfConsExt; eauto.
       * inverts_kind. eauto.
       * erewrite mergeT_substTT.
         eapply typef_stprops_snoc. auto.
         eauto. eauto.
  }

 (*********************************************************)
 (* Pop and extend frame from the stack, 
    and merge the new region with the old one. *)
 Case "SfExtendPop".
 { inverts_typec.
   set (r1 := TRgn p1).
   set (r2 := TRgn p2).
   exists (mergeTE p1 p2 se).
   exists e0.
   rip.

   (* Extends of SE no longer true *)
   - skip.  (* BROKEN *)

   (* Updated store is well formed. *)
   - admit. 

   (* Updated store is live relative to frame stack. *)
   - admit.

   (* Frame stack is live relative to effect. *) 
   - admit.

   (* Effect of result is subsumed by previous. *)
   - admit.  (* ok, via EquivT *)

   (* Resulting state is well typed. *)
   - eapply TcExp
       with (t1 := mergeT p1 p2 t1)
            (e1 := TBot KEffect)
            (e2 := e0).

     (* Equivalence of result effect. *)
     + have (KindT nil sp (TSum (TBot KEffect) (TSum e0 (TAlloc (TRgn p1)))) KEffect).
       inverts_kind.
       eapply EqSym; eauto.

     (* Result value is well typed. *)
     + rgwrite (nil                    = mergeTE p1 p2 nil).
       rgwrite (XVal (mergeV p1 p2 v1) = mergeX  p1 p2 (XVal v1)).
       rgwrite (TBot KEffect           = mergeT  p1 p2 (TBot KEffect)).
       eapply mergeX_typeX. auto. eauto.

     (* Popped frame stack is well typed. *)
     + rgwrite (nil = mergeTE p1 p2 nil).
       eapply typef_merge; eauto.
 }

 (*********************************************************)
 (* Allocate a reference. *)
 Case "SfStoreAlloc".
 { inverts HC.
   inverts H0.
   exists (TRef   (TRgn r1) t2 <: se).
   exists e2.
   rip.

   (* All store bindings mentioned by frame stack are still live. *)
   - remember (TRgn r1) as p.

     have (SubsT nil sp e (TAlloc p) KEffect)
      by  (eapply EqSym in H; eauto).

     have (LiveE fs (TAlloc p)).

     assert (In (FPriv r1) fs).
      eapply liveE_fPriv_in; eauto.
      subst p. simpl. auto.
     
     eapply liveS_stvalue_snoc; auto.

   (* Resulting effects are to live regions. *)
   - have  (SubsT nil sp e e2 KEffect)
      by   (eapply EqSym in H; eauto).
     eapply liveE_subsT; eauto.

   (* Original effect visibly subsumes resulting one. *)
   - eapply EqSym in H.
      eapply subsT_subsVisibleT; eauto.
      eauto. eauto.

   (* Resulting configuation is well typed. *)
   - eapply TcExp
      with (t1 := TRef (TRgn r1) t2)
           (e1 := TBot KEffect)
           (e2 := e2).
     + eapply EqSym.
        * eauto. 
        * eapply KiSum; eauto.
        * eapply equivT_sum_left; eauto.
     + eapply TxVal.
       eapply TvLoc.
        have    (length se = length ss).
        rrwrite (length ss = length se).
        eauto. eauto.
     + eauto.
 }


 (*********************************************************)
 (* Read from a reference. *)
 Case "SfStoreRead".
 { inverts HC.
   exists se.
   exists e2. 
   rip.

   (* Resulting effects are to live regions. *)
   - have  (SubsT nil sp e e2 KEffect)
      by   (eapply EqSym in H0; eauto).
     eapply liveE_subsT; eauto.

   (* Original effect visibly subsumes resulting one. *)
   - eapply EqSym in H0.
      eapply subsT_subsVisibleT; eauto.
      eauto. eauto.

   (* Resulting configutation is well typed. *)
   - eapply TcExp
      with (t1 := t1)
           (e1 := TBot KEffect)
           (e2 := e2).
     + eapply EqSym; eauto.
     + inverts H1.
       inverts H12.
       eapply TxVal.
        inverts HH. rip.
        eapply storet_get_typev; eauto.
     + eauto.
 }


 (*********************************************************)
 (* Write to a reference. *)
 Case "SfStoreWrite".
 { inverts HC.
   exists se.
   exists e2.
   rip.

   (* Resulting store is well formed. *)
   - inverts_type.
     eapply wfFS_stbind_update; eauto.

   (* All store bindings mentioned by frame stack are still live. *)
   - eapply liveS_stvalue_update.
     + inverts_type.
       remember (TRgn r) as p.

       have (SubsT nil sp e (TWrite p) KEffect)
        by  (eapply EqSym in H0; eauto).

       have (LiveE fs (TWrite p))
        by  (eapply liveE_subsT; eauto).

       eapply liveE_fPriv_in with (e := TWrite p).
        subst p. snorm. eauto.

     + auto.

   (* Resulting effects are to live regions. *)
   - have  (SubsT nil sp e e2 KEffect)
      by   (eapply EqSym in H0; eauto).
     eapply liveE_subsT; eauto.

   (* Original effect visibly subsumes resulting one. *)
    - eapply EqSym in H0.
      eapply subsT_subsVisibleT; eauto.
       eauto. eauto.

   (* Resulting configuration is well typed. *)
   - eapply TcExp
      with (t1 := t1)
           (e1 := TBot KEffect)
           (e2 := e2).
     + eapply EqSym; eauto.
     + inverts_type.
       eapply TxVal.
        inverts HH. rip.
     + eauto.
 }
Qed.
