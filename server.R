library(shiny)
library(dplyr)
library(shinyjs)

fields = read.table(header=T, text = "
Name                        Group         Type
NHI                         Patient       text
StrokeOnsetTime_date        Patient       date
StrokeOnsetTime_time        Patient       time
CurrentLocation             Patient       selecttext
pastaAfterhours             Pasta         bool
pastaWTK                    Pasta         bool
pastaAge                    Pasta         bool
pastaFunction               Pasta         bool
pastaBSL                    Pasta         bool
pastaGCS                    Pasta         bool
pastaOnsetTime              Pasta         bool
pastaLAMS                   Pasta         bool
pastaLAMSFace               LAMS          radionum
pastaLAMSArm                LAMS          radionum
pastaLAMSGrip               LAMS          radionum
pastaNeurologistAccepted    Pasta2        bool
pastaDepartSceneTime_date   Pasta2        date
pastaDepartSceneTime_time   Pasta2        time
NeurologistTriageDecision   Neurologist   selecttext
HospitalArrivalTime_date    Resus         date
HospitalArrivalTime_time    Resus         time
CTTime_date                 Resus         date
CTTime_time                 Resus         time
ResusDiagnosis              Resus         selecttext
NIHSS                       Resus         num
Thrombolysis                Resus         bool
ThrombolysisTime_date       Resus         date
ThrombolysisTime_time       Resus         time
ClotRetrieval               Angio         bool
ClotRetrievalTime_date      Angio         date
ClotRetrievalTime_time      Angio         time    
ClotRetrievalOutcome        Angio         selecttext
DischargeDate               Ward          date
DischargeType               Ward          selecttext
SICH                        Ward          bool
PathwayInitiation           Patient       selecttext
MRS3Months                  Patient       num
Completed                   Patient       bool
")

shinyServer(function(input, output, session) {
  
  vals = reactiveValues(
    currentNHI = ""
  )
  
  getPatients = reactive({
    if (is.null(vals[["patients"]])) {
      # TODO: Implement saving/loading
      # DF = read.csv("data/patients.csv", stringsAsFactors = F, header=T)
      # DF$onsetDate = ymd(DF$onsetDate)
      DF = data.frame()
    }
    else
      DF = vals[["patients"]]
    
    vals[["patients"]] = DF
    DF
  })
  
  getCurrentPatients = reactive({
    getPatients() %>% 
      filter(Completed==F)
  })
  
  # Whenever a field is filled, aggregate all form data
  getFormData <- reactive({
    cat("getFormData\n")
    formData <- sapply(fields, function(x) input[[x]])
    formData
  })
  
  # NEW PATIENT
  # ======================================

  observeEvent(input$btnNewPatient, {
    showModal(modalDialog(
      title = "Start New Patient",
        textInput("newptNHI", "NHI", value=""),
        selectInput("newptLocation", "Current Location", choices=c("Unknown","PreHospital","Resus/CT", "Angio/PACU", "Wd63","DCC","Other")),
        datetimeInput("newptStrokeOnsetTime", "Symptom Onset Date and Time"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("btnNewPatientOK", "OK")
      )
    ))
  })
  
  # new patient modal dialog OK
  observeEvent(input$btnNewPatientOK, {
    if (!is.null(input$newptNHI)) {
      vals$currentNHI = input$newptNHI
      vals$patients = rbind(getPatients(), newPatient(NHI = input$newptNHI, Location=input$newptLocation, StrokeOnsetTime = input$newptStrokeOnsetTime))
      updateDateInput(session, "StrokeOnsetTime_date", value=input$newptStrokeOnsetTime_date)
      updateTimeInput(session, "StrokeOnsetTime_time", value=input$newptStrokeOnsetTime_time)
      updateSelectInput(session, "CurrentLocation", selected=input$newptLocation)
      removeModal()
    }
  })
  
  newPatient = function(NHI, Location, StrokeOnsetTime) {
    res = cbind(
      NHI = NHI,
      Location = Location,
      StrokeOnsetTime = StrokeOnsetTime,
      Completed = F,
      pastaAfterhours = F,
      pastaWTK = F,
      pastaAge = F,
      pastaFunction = F,
      pastaBSL = F,
      pastaGCS = F,
      pastaOnsetTime = F,
      pastaLAMSFace = F,
      pastaLAMSArm = F,
      pastaLAMSGrip = F,
      pastaLAMS = F,
      pastaNeurologist = F,
      amboDepartSceneTime = ""
    )
  }
  
  # update current NHI selection following creation of a new patient
  observe({
    NHIs = as.vector(getCurrentPatients()$NHI)
    if (!is.null(NHIs)) {
      updateSelectInput(session, "NHI", choices=NHIs, selected=NHIs[length(NHIs)])
    }
  })
  
  # PASTA
  # ==============================
  
  # automatic calculation of LAMS Total
  observe({
    lamsFace = sum(as.numeric(c(input$pastaLAMSArm, input$pastaLAMSFace, input$pastaLAMSGrip)))
    updateCheckboxInput(session, "pastaLAMS", value=(lamsFace>2))
  })
  
  observe({
    res=sapply(as.vector(fields$Name[fields$Group=="Pasta"]), function(x) input[[x]])
    if(all(res))
      updateTextInput(session, "pastaResult", value="PASSED")
    else
      updateTextInput(session, "pastaResult", value="FAILED")
  })
  
  # CLOCKS
  # =============================
  
  # update clocks after NHI change
  observe({
    if (input$NHI != "") {
      x = getElapsedTime("StrokeOnsetTime")
      if (!is.na(x)) {
        runjs(sprintf("clock[0].setTime(%i); clock[0].start();", x*60))
      }
      x = getElapsedTime("HospitalArrivalTime")
      if (!is.na(x)) {
        runjs(sprintf("clock[1].setTime(%i); clock[1].start();", x*60))
      }
    }
  })
  
  # TIME
  # ============================
  
  setDateTime = function(id, datetime) {
    updateDateInput2(session, paste0(id,"_date"), value=datetime)
    updateTimeInput(session, paste0(id,"_time"), value=datetime)
  }
  
  getDateTime = function(id) {
    mydate = input[[paste0(id,"_date")]]
    mytime = strftime(input[[paste0(id,"_time")]], format="%H:%M")
    parse_date_time(paste0(mydate," ",mytime), "Ymd HM", tz="Pacific/Auckland")
  }
  
  getElapsedTime = function(id) {
    x = getDateTime(id)
    if (!is.na(x)) {
      elapsedmins = difftime(now(tzone="Pacific/Auckland"), x, units="mins")
      return(as.integer(elapsedmins))
    }
    return(NA)
  }
  
  observeEvent(input$newptStrokeOnsetTime_now, { setDateTime("newptStrokeOnsetTime", now(tzone="Pacific/Auckland")) })
  observeEvent(input$StrokeOnsetTime_now, { setDateTime("StrokeOnsetTime", now(tzone="Pacific/Auckland")) })
  observeEvent(input$amboDepartSceneTime_now, { setDateTime("amboDepartSceneTime", now(tzone="Pacific/Auckland")) })
  observeEvent(input$HospitalArrivalTime_now, { setDateTime("HospitalArrivalTime", now(tzone="Pacific/Auckland")) })
  observeEvent(input$CTTime_now, { setDateTime("CTTime", now(tzone="Pacific/Auckland")) })
  observeEvent(input$ThrombolysisTime_now, { setDateTime("ThrombolysisTime", now(tzone="Pacific/Auckland")) })
  observeEvent(input$ClotRetrievalTime_now, { setDateTime("ClotRetrievalTime", now(tzone="Pacific/Auckland")) })
  
})
