


pastaFields = c(
  "pastaAfterhours",
  "pastaWTK",
  "pastaAge",
  "pastaFunction",
  "pastaBSL",
  "pastaGCS",
  "pastaOnsetTime",
  "pastaLAMS")

lamsFields = c(
  "pastaLAMSFace",
  "pastaLAMSArm",
  "pastaLAMSGrip"
)

fields = c(
  # New or Current Patient
  "NHI",
  "StrokeOnsetTime_date",
  "StrokeOnsetTime_time",
  "CurrentLocation",
  
  # AMBO
  pastaFields,
  lamsFields,
  "pastaNeurologistAccepted",
  "amboDepartSceneTime_date",
  "amboDepartSceneTime_time",
  
  # Neurologist
  "NeurologistTriageDecision",
  
  # Resus
  "HospitalArrivalTime_date",
  "HospitalArrivalTime_time",
  "CTTime_date",
  "CTTime_time",
  "ResusDiagnosis",
  "NIHSS",
  "Thrombolysis",
  "ThrombolysisTime_date",
  "ThrombolysisTime_time",
  
  # Angio
  "ClotRetrieval",
  "ClotRetrievalTime_date",
  "ClotRetrievalTime_time",
  "ClotRetrievalOutcome",
  
  # Ward
  "DischargeDate",
  "DischargeType",
  "SICH",
  
  # Patient
  "PathwayInitiation",
  "MRS3Months",
  "Completed"
)