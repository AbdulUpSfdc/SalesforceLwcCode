// Trigger to consume platform events related to Case Milestones
trigger BWC_CaseMilestoneEvent_Trigger on Case_Milestone_Event__e(after insert) {
    SFS_TriggerHandler.run();
}