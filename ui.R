library(shiny)
library(shinyjs)

source("utils.R")

shinyUI(fluidPage(

  # Application title
  titlePanel("Auckland Hyperacute Stroke Pathway"),

  # Sidebar
  sidebarLayout(
    sidebarPanel(
      
      useShinyjs(),
      
      titledPanel("Patients",
        actionButton("btnNewPatient","Start New Patient",width="100%", class="btn btn-success"),
        h4("OR", style="text-align:center"),
        selectInput("NHI", "Select Existing Active NHI", choices=c())),
      
      conditionalPanel(condition="input.NHI != ''",
        titledPanel("Current Patient",
          selectInput("CurrentLocation", "Location", choices=c("Unknown","PreHospital","Resus/CT", "Angio/PACU", "Wd63","DCC","Other")),
          flipclock("onsetTimer", "Time since stroke onset"),
          flipclock("doorTimer", "Time since hospital arrival"),
          actionButton("btnSaveCurrentPatient","Save Changes", width="100%", class="btn btn-alert", style="margin-top:20px"))),

    width=3),

    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Help", style="margin-top: 20px",
          div(class="alert alert-info",
            p("Click 'Start New Patient' to begin collecting data for a new hyperacute stroke patient, OR select an exisiting patient from the drop down list. Use the tabs above to select location relevant data entry.")
          ),
          img(src="pathway.PNG", style="width:100%; height:100%")
        ),
        
        tabPanel("Ambo", style="margin-top:20px",
          fluidRow(
            column(width=6,
              div(class="alert alert-info",
                h4("Prehospital Acute Stroke Triage in Auckland (PASTA)"),
                helpText("Must answer YES to ALL criteria.")),
              #p("Although any negative response will exclude the patient please answer all questions if possible for audit purposes."),
              checkboxInput("pastaAfterhours", "Is the Hospital ETA after-hours? (M-F: 1600-0800h OR Weekend/Public Holiday)",width="100%"),
              checkboxInput("pastaWTK",        "Is the patient being collected in the WTK catchment area?",width="100%"),
              checkboxInput("pastaAge",        "Is the patient >= 15y old?",width="100%"),
              checkboxInput("pastaFunction",   "Is the baseline functional level at least semi-independent?",width="100%"),
              checkboxInput("pastaBSL",        "Is the blood sugar level between 4-17mmol/L inclusive?",width="100%"),
              checkboxInput("pastaGCS",        "Is the GCS motor score 5 (withdraws to pain) or 6 (obeys commands)?",width="100%"),
              checkboxInput("pastaOnsetTime",  "Is the time of symptom onset <5h ago?",width="100%")),
            column(width=6,
              div(class="alert alert-info",
                h4("Los Angeles Motor Scale (LAMS)"),
                helpText("Score weakest side")),
              radioButtons("pastaLAMSFace", "Facial Weakness", choices=c("Absent=0"=0,"Present=1"=1),width="100%", inline=T),
              radioButtons("pastaLAMSArm",  "Arm Weakness", choices=c("Absent=0"=0,"Drift=1"=1,"Falls rapidly=2"=2),width="100%",inline=T),
              radioButtons("pastaLAMSGrip", "Grip strength", choices=c("Normal=0"=0,"Weak=1"=1,"No grip=2"=2),width="100%",inline=T),
              checkboxInput("pastaLAMS",    "Is the total LAMS >= 3?",width="100%"),
              hiddenTextInput("pastaResult", value="FAILED"))),
          fluidRow(
            column(width=12, 
              conditionalPanel("input.pastaResult=='PASSED'",
                div(class="alert alert-success",
                  helpText("Patient meets all criteria, now ring 021-XXX-XXXX for final confirmation with oncall neurologist."),
                  checkboxInput("pastaNeurologistAccepted", "Accepted by the oncall neurologist?", width="100%"),
                  helpText("If the patient is accepted by the oncall neurologist transport patient directly to ACH resus. If not accepted transfer to nearest ED as usual."),
                  datetimeInput("pastaDepartSceneTime", "Depart Scene Date and Time")
                )
              ),
              conditionalPanel("input.pastaResult=='FAILED'",
                div(class="alert alert-warning",
                  p("Patient must meet all criteria above. If patient did not meet all criteria transfer to nearest ED as usual."))
              )
            )
          )
        ),
        
        tabPanel("Neurologist", style="margin-top:20px",
          div(class="alert alert-info",
              p("PASTA triage philosophy: Is the patient more likely to be advantaged than disadvantaged by diverting past local ED. To be advantaged the patient should be a potential hyperacute intervention candidation. Patients where either stroke or hyperacute intervention are unlikely may be disadvantaged by diversion. 
                The decision rests with the oncall neurologist who is at liberty to deviate from the pathway criteria based on a case by case basis")),
          div(class="alert alert-warning",
              p("Patient accepted for diversion: call XXX-XXXX and ask for 'Hyperacute Stroke Code: ETA resus xx min'"),
              p("Patient accepted for clot retrieval: call XXX-XXXX and ask for 'Stroke Clot Retrieval Code: ETA resus xx min'")),
          titledPanel("PASTA and Prehospital",
            selectInput("NeurologistTriageDecision","PreHospital Triage Decision", choices=c(
              "Not applicable",
              "Patient Accepted",
              "Diagnostic uncertainty",
              "Functional or comorbid status",
              "Unfavourable timeframe",
              "PreADHB imaging unfavourable"
            ))),
            img(src="prehospital.PNG", style="width:100%;height:100%")
          ),
        
        tabPanel("Nurse", style="margin-top:20px",
          div(class="alert alert-warning",
            p("Alpha version only. Needs nursing input")),
          titledPanel("Prehospital Checklist",
            checkboxInput("nurseNHI", "If NHI available call admitting to have patient registered as neurology expected arrival. If possible pre-print stickers. This step is particularly important for clot retrieval patients from other DHBs.", width="100%"),
            checkboxInput("nurseBedspace", "Ensure bedspace available in the Wd63 hyperacute unit", width="100%"),
            checkboxInput("nursePreprint", "Pre-print Thrombolysis Documents, Consent and NIHSS scoring sheets: insert link here", width="100%"),
            checkboxInput("nurseAwait", "Await patient in resus and escort. PASTA patients will require a brief ABC assessment. Then help escort patient to CT", width="100%")),
          titledPanel("Thrombolysis Checklist",
            checkboxInput("nurseThrombolysisBP", "Blood pressure within target range?", width="100%"),
            checkboxInput("nurseThrombolysisWt", "Obtain or guess patient weight and calculate dose", width="100%"),
            numericInput("nurseWeight", "Patient Weight (kg)", NA),
            numericInput("nurseAlteplaseTotalDose", "Alteplase Total Dose (mg)", NA),
            numericInput("nurseAlteplaseTotalDose", "Alteplase 10% loading dose (mg)", NA),
            numericInput("nurseAlteplaseTotalDose", "Alteplase 90% 1 hour infusion dose (mg)", NA),
            checkboxInput("nurseConsent","Has consent been obtained?", width="100%")),
          titledPanel("Clot Retrieval/Angio Checklist",
            p("Work in progress..."),
            checkboxInput("nurseAngioBed", "Order a ward 63 be bought down to angio", width="100%")),
          titledPanel("Ward Checklist",
            p("Work in progress..."),
            p("See intranet for post thrombolysis and post clot retrieval management pathways", width="100%"))
        ),
        
        tabPanel("Resus", style="margin-top:20px",
          div(class="alert alert-info",
            p("Patient should be briefly examined for ABC on ambulance stretcher without connection to resus equipment. If stable patient to be taken on ambulance stretcher immediately to CT for CT + CTA. Send resus bed to collect patient after CT.")),
          
          fluidRow(
            column(6,
              datetimeInput("HospitalArrivalTime", "Hospital Arrival Date and Time"),
              datetimeInput("CTTime", "CT Date and Time"),
          
              selectInput("ResusDiagnosis", "Resus Diagnosis", choices=c("ICH","Ischemic stroke with LVO", "Ischemic stroke without LVO", "TIA", "Stroke Mimic", "Other")),
              numericInput("NIHSS", "NIHSS", value=NA),
          
              checkboxInput("Thrombolysis", "Thrombolysed?"),
              conditionalPanel(condition="input.Thrombolysis == true",
                datetimeInput("ThrombolysisTime","Thrombolysis Date and Time"))),
            column(6,
              img(src="inhospital.PNG", style="width:100%;height:100%"))
          ) # fluidrow
        ), # tabpanel Resus
          
        tabPanel("Angio", style="margin-top:20px",
          checkboxInput("ClotRetrieval", "Clot retrieval or angiography performed?"),
          conditionalPanel(condition="input.ClotRetrieval == true",
            datetimeInput("ClotRetrievalTime","Clot Retrieval Groin Date and Time"),
            selectInput("ClotRetrievalOutcome", "Clot Retrieval Outcome", choices=c("Success", "Technical Failure", "Angiography Only")))),
        
        tabPanel("Ward", style="margin-top:20px",
          dateInput("DischargeDate","Discharge Date"),
          selectInput("DischargeType","Discharge Destination", choices=c("Another DHB","Home", "Rehab")),
          conditionalPanel("input.Thrombolysis == true || input.ClotRetrieval == true",
            checkboxInput("SICH", "Symptomatic ICH"))),
        
        tabPanel("Patient", style="margin-top:20px",
          datetimeInput("StrokeOnsetTime", "Stroke Symptom Onset Date and Time"),
          selectInput("PathwayInitiation", "Hyperacute pathway initiation point", choices=c(
            "Unknown",
            "Community ADHB area",
            "Community PASTA",
            "WDHB ED",
            "ADHB ED",
            "ADHB Ward",
            "CMDHB ED",
            "Northland DHB",
            "Waikato DHB",
            "Other DHB",
            "Other location"
          )),
          selectInput("MRS3months", "MRS at 3 months", choices=c(
            "Unknown=-1"=-1,
            "No symptoms=0"=0, 
            "Symptoms but no disability=1"=1,
            "Mild disability but independent ADL=2"=2,
            "Moderate disability but able to walk=3"=3,
            "Severe disability, need assist all ADL=4"=4,
            "Bedridden, private hospital=5"=5,
            "Dead=6"=6), selected=""),
          checkboxInput("Completed", "Patient record completed", value=F),
          p("KPIs")
        ),
        
        id="mainTabset"
      ) # tabset
    ) # mainpanel
  )
))
