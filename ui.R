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
          flipclock("onsetTimer", "Time since stroke onset"),
          flipclock("doorTimer", "Time since hospital arrival"))),

    width=3),

    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Help", style="margin-top: 20px",
          div(class="alert alert-info",
            p("Click 'Start New Patient' to begin collecting data for a new hyperacute stroke patient, OR select an exisiting patient from the drop down list. Use the tabs above to select location relevant data entry."))),
        
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
              checkboxInput("pastaLAMS",    "Is the total LAMS >= 3?",width="100%"))),
          fluidRow(
            column(width=12, uiOutput("htmlPASTAResult")))),
        
        tabPanel("Resus", style="margin-top:20px",
          div(class="alert alert-info",
            p("Patient should be briefly examined for ABC on ambulance stretcher without connection to resus equipment. If stable patient to be taken on ambulance stretcher immediately to CT for CT + CTA. Send resus bed to collect patient after CT.")),
          
          datetimeInput("datetimeHospitalArrival", "Hospital Arrival Date and Time"),
          datetimeInput("datetimeCT", "CT Date and Time"),
          
          selectInput("selInitialDiagnosis", "Resus Diagnosis", choices=c("ICH","Ischemic stroke with LVO", "Ischemic stroke without LVO", "TIA", "Stroke Mimic", "Other")),
          numericInput("numNIHSS", "NIHSS", value=0),
          
          checkboxInput("chkThrombolysis", "Thrombolysed?"),
          conditionalPanel(condition="input.chkThrombolysis == true",
            datetimeInput("datetimeThrombolysis","Thrombolysis Date and Time", width="100%"))),
          
        tabPanel("Angio", style="margin-top:20px",
          checkboxInput("chkClotRetrieval", "Clot retrieval or angiography performed?"),
          conditionalPanel(condition="input.chkClotRetrieval == true",
            datetimeInput("datetimeClotRetrieval","Clot Retrieval Groin Date and Time"),
            selectInput("selClotRetrievalOutcome", "Clot Retrieval Outcome", choices=c("Success", "Technical Failure", "Angiography Only")))),
        
        tabPanel("Ward", style="margin-top:20px",
          dateInput("dateDischarge","Discharge Date"),
          selectInput("selDischargeType","Discharge Destination", choices=c("Another DHB","Home", "Rehab")),
          conditionalPanel("input.chkThrombolysis == true || input.chkClotRetrieval == true",
            checkboxInput("chkSICH", "Symptomatic ICH"))),
        
        id="mainTabset"
      ) # tabset
    ) # mainpanel
  )
))
