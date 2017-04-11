library(shiny)
library(dplyr)
library(shinyjs)
library(shinyTime)

updateDateInput2 = function (session, inputId, label = NULL, value = NULL, min = NULL, max = NULL) 
{
  formatDate <- function(x) {
    if (is.null(x)) 
      return(NULL)
    format(as.Date(x, tz="Pacific/Auckland"), "%Y-%m-%d")
  }
  value <- formatDate(value)
  min <- formatDate(min)
  max <- formatDate(max)
  message <- shiny:::dropNulls(list(label = label, value = value, min = min, 
                                    max = max))
  session$sendInputMessage(inputId, message)
}

updateTimeInput2 = function (session, inputId, value = NA) 
{
  if (is.null(value)) 
    value=""
  else if (is.na(value))
    value=""
  else
    value <- shinyTime:::parseTimeFromValue(value)
  message <- list(value = value)
  session$sendInputMessage(inputId, message)
}

fields = read.table(header=T, stringsAsFactors=F, text = "
Name                        Group         Type
NHI                         Patient       text
StrokeOnsetTime             Patient       datetime
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
pastaDepartSceneTime        Pasta2        datetime
NeurologistTriageDecision   Neurologist   selecttext
HospitalArrivalTime         Resus         datetime
CTTime                      Resus         datetime
ResusDiagnosis              Resus         selecttext
NIHSS                       Resus         num
Thrombolysis                Resus         bool
ThrombolysisTime            Resus         datetime
ClotRetrieval               Angio         bool
ClotRetrievalTime           Angio         datetime
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
      DF = read.csv("patients.csv", stringsAsFactors = F, header=T)
      # DF$onsetDate = ymd(DF$onsetDate)
      # DF = data.frame()
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
  
  getPatient = function(uNHI) {
    getPatients() %>% 
      filter(NHI==uNHI)
  }
  
  # Whenever a field is filled, aggregate all form data
  getFormData <- reactive({
    cat("getFormData\n")
    formData <- 
    formData
  })
  
  observeEvent(input$btnSaveCurrentPatient, {
    showModal(modalDialog(
      title = "Save Changes",
      helpText("Disabled for demo")
    ))
    # x = data.frame(dummy="")
    # for (fieldname in fields$Name) {
    #   x[[fieldname]] = ifelse(is.null(input[[fieldname]]) | is.na(input[])
    # }
    # # x = sapply(as.vector(fields$Name), function(x) paste(input[[x]]))
    # # for (datename in fields$Name[fields$Type == "datetime"]) {
    # #   x[[datename]] = getDateTime(datename)
    # # }
    # # x=as.data.frame(t(x))
    # a=1
    # b=2
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
      np = newPatient(NHI = input$newptNHI, Location=input$newptLocation, StrokeOnsetTime = getDateTimeStr("newptStrokeOnsetTime"))
      vals$patients = rbind(getPatients(), np)
      updateDateInput(session, "StrokeOnsetTime_date", value=input$newptStrokeOnsetTime_date)
      updateTimeInput(session, "StrokeOnsetTime_time", value=input$newptStrokeOnsetTime_time)
      updateSelectInput(session, "CurrentLocation", selected=input$newptLocation)
      removeModal()
    }
  })
  
  newPatient = function(NHI, Location, StrokeOnsetTime) {
    res = data.frame(NHI = NHI, StrokeOnsetTime = StrokeOnsetTime, CurrentLocation=Location,
                     pastaAfterhours=F, pastaWTK=F,pastaAge=F,pastaFunction=F,pastaBSL=F,pastaGCS=F,pastaOnsetTime=F,
                     pastaLAMS=F, pastaLAMSFace=0,pastaLAMSArm=0,pastaLAMSGrip=0,pastaNeurologistAccepted=F,
                     pastaDepartSceneTime=NA,NeurologistTriageDecision="",HospitalArrivalTime=NA,CTTime=NA,ResusDiagnosis="",
                     NIHSS=NA, Thrombolysis=F, ThrombolysisTime=NA,ClotRetrieval=F,ClotRetrievalTime=NA,ClotRetrievalOutcome="",
                     DischargeDate=NA,DischargeType="", SICH=F, PathwayInitiation="", MRS3Months=NA, Completed=F)
  }
  
  # update current NHI selection following creation of a new patient or loading data
  observe({
    pts = getCurrentPatients()
    if (nrow(pts)>0) {
      updateSelectInput(session, "NHI", choices=as.vector(pts$NHI), selected=pts$NHI[length(pts$NHI)])
    }
  })
  
  observe({
    pt = getPatient(input$NHI)
    if (nrow(pt)>0) {
      print(pt$NHI)
      for (i in 2:nrow(fields)) {
        fieldname = fields$Name[i]
        fieldtype = fields$Type[i]
        
        if (fieldtype == "bool")
          updateCheckboxInput(session, inputId=fieldname, value=pt[[fieldname]])
        if (fieldtype == "selecttext")
          updateSelectInput(session, inputId=fieldname, selected=pt[[fieldname]])
        if (fieldtype == "datetime")
        {
          setDateTime(fieldname, pt[[fieldname]])
        }
        if (fieldtype == "radionum")
          updateRadioButtons(session, inputId=fieldname, selected=pt[[fieldname]])
        if (fieldtype == "date")
          updateDateInput2(session, inputId=fieldname, value=pt[[fieldname]])
        if (fieldtype == "num")
          updateNumericInput(session, inputId=fieldname, value=pt[[fieldname]])
      }
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
        if (x > 7200)
          runjs(sprintf("clock[0].reset(); clock[0].stop();"))
        else
          runjs(sprintf("clock[0].setTime(%i); clock[0].start();", x*60))
      }
      
      x = getElapsedTime("HospitalArrivalTime")
      if (!is.na(x)) {
        if (x>7200)
          runjs(sprintf("clock[1].reset(); clock[1].stop();"))
        else
          runjs(sprintf("clock[1].setTime(%i); clock[1].start();", x*60))
      }
    }
  })
  
  # TIME
  # ============================
  
  setDateTime = function(id, datetime) {
    updateDateInput2(session, paste0(id,"_date"), value=datetime)
    updateTimeInput2(session, paste0(id,"_time"), value=datetime)
  }
  
  getDateTime = function(id) {
    mydate = input[[paste0(id,"_date")]]
    mytime = strftime(input[[paste0(id,"_time")]], format="%H:%M")
    mydatetime = paste0(mydate," ",mytime)
    if (mydatetime==" ")
      return (NA)
    else
      parse_date_time(paste0(mydate," ",mytime), "Ymd HM", tz="Pacific/Auckland")
  }
  
  getDateTimeStr = function(id) {
    strftime(getDateTime(id), format="%Y-%m-%d %H:%M")
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
