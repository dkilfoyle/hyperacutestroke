library(shiny)
library(shinyjs)

shinyUI(fluidPage(

  # Application title
  titlePanel("Auckland Hyperacute Stroke Pathway"),

  # Sidebar
  sidebarLayout(
    sidebarPanel(
      
      includeScript("www/flipclock.js"),
      includeCSS("www/flipclock.css"),
      useShinyjs(),
      
      wellPanel(actionButton("btnNewPatient","Start New Patient",width="100%")),

      selectInput("selCurrentNHI", "Current Patient", choices=c()),
      
      # TODO: Replace timer textboxs with a digital stopwatch and/or progress meter flipclock.js?
      div(id="onsetTimer"),
      div(id="doorTimer")
      
      # textInput("timerOnset", "Onset Timer"),
      # textInput("timerDoor", "Door Timer")
    ),

    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Help",
          h4("Information"),
          helpText("Click 'Start New Patient' to begin collecting data for a new hyperacute stroke patient, OR select an exisiting patient from the drop down list. Use the tabs above to select location relevant data entry.")),
        
        tabPanel("Ambo",
          h4("Prehospital Acute Stroke Triage in Auckland (PASTA)"),
          helpText("Must answer YES to ALL criteria."),
          #p("Although any negative response will exclude the patient please answer all questions if possible for audit purposes."),
          checkboxInput("chkAfterhours", "Is the Hospital ETA after-hours? (M-F: 1600-0800h OR Weekend/Public Holiday)",width="100%"),
          checkboxInput("chkWTK",        "Is the patient being collected in the WTK catchment area?",width="100%"),
          checkboxInput("chkAge",        "Is the patient >= 15y old?",width="100%"),
          checkboxInput("chkFunction",   "Is the baseline functional level at least semi-independent?",width="100%"),
          checkboxInput("chkBSL",        "Is the blood sugar level between 4-17mmol/L inclusive?",width="100%"),
          checkboxInput("chkGCS",        "Is the GCS motor score 5 (withdraws to pain) or 6 (obeys commands)?",width="100%"),
          checkboxInput("chkOnsetTime",  "Is the time of symptom onset <5h ago?",width="100%"),
          h4("Los Angeles Motor Scale (LAMS)"),
          helpText("Score weakest side"),
          radioButtons("radLAMSFace", "Facial Weakness", choices=c("Absent=0"=0,"Present=1"=1),width="100%", inline=T),
          radioButtons("radLAMSArm",  "Arm Weakness", choices=c("Absent=0"=0,"Drift=1"=1,"Falls rapidly=2"=2),width="100%",inline=T),
          radioButtons("radLAMSGrip", "Grip strength", choices=c("Normal=0"=0,"Weak=1"=1,"No grip=2"=2),width="100%",inline=T),
          checkboxInput("chkLAMS",    "Is the total LAMS >= 3?",width="100%"),
          uiOutput("htmlPASTAResult")),
        
        tabPanel("Resus",
          helpText("Patient should be briefly examined for ABC on ambulance stretcher without connection to resus equipment. If stable patient to be taken on ambulance stretcher immediately to CT for CT + CTA. Send resus bed to collect patient after CT."),
          dateInput("dateHospitalArrival","Hospital Arrival Date"),
          timeInput("timeHospitalArrival", "Hospital Arrival Time"),
          dateInput("dateCT","CT Date"),
          timeInput("timeCT", "CT Time"),
          selectInput("selInitialDiagnosis", "Resus Diagnosis", choices=c("ICH","Ischemic stroke with LVO", "Ischemic stroke without LVO", "TIA", "Stroke Mimic", "Other")),
          numericInput("numNIHSS", "NIHSS", value=0),
          checkboxInput("chkThrombolysis", "Thrombolysed?"),
          conditionalPanel(condition="input.chkThrombolysis == true",
            dateInput("dateThrombolysis","Thrombolysis Date", width="100%"),
            timeInput("timeThrombolysis", "Thrombolysis Time"))),
          
        tabPanel("Angio",
          checkboxInput("chkClotRetrieval", "Clot retrieval or angiography performed?"),
          conditionalPanel(condition="input.chkThrombolysis == true",
            dateInput("dateClotRetrieval","Clot Retrieval Groin Date"),
            timeInput("timeClotRetrieval", "Clot Retrieval Groin Time"),
            selectInput("selClotRetrievalOutcome", "Clot Retrieval Outcome", choices=c("Success", "Technical Failure", "Angiography Only")))),
        
        tabPanel("Ward",
          dateInput("dateDischarge","Discharge Date"),
          selectInput("selDischargeType","Discharge Destination", choices=c("Another DHB","Home", "Rehab")),
          conditionalPanel("input.chkThrombolysis == true || input.chkClotRetrieval == true",
            checkboxInput("chkSICH", "Symptomatic ICH"))),
        
        id="mainTabset"
      ) # tabset
    ) # mainpanel
  )
))
