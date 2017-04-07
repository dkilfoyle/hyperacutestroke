library(shiny)
library(dplyr)
library(shinyjs)

shinyServer(function(input, output, session) {
  
  vals = reactiveValues(
    currentNHI = ""
  )
  
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
    "NHI",
    "StrokeOnsetTime_date",
    "StrokeOnsetTime_time",
    "CurrentLocation",
    "Completed",
    
    pastaFields,
    lamsFields,
    "pastaNeurologist",
    "amboDepartSceneTime_date",
    "amboDepartSceneTime_time",
    "HospitalArrivalTime_date",
    "HospitalArrivalTime_time"
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
  
  # new patient modal dialog OK
  observeEvent(input$btnNewPatientOK, {
    if (!is.null(input$newptNHI)) {
      vals$currentNHI = input$newptNHI
      vals$patients = rbind(getPatients(), newPatient(NHI = input$newptNHI, Location=input$newptLocation, StrokeOnsetTime = input$newptStrokeOnsetTime))
      updateDateInput(session, "StrokeOnsetTime_date", value=input$newptStrokeOnsetTime_date)
      updateTimeInput(session, "StrokeOnsetTime_time", value=input$newptStrokeOnsetTime_time)
      removeModal()
    }
  })
  
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
  
  output$htmlPASTAResult = renderUI({
    #TODO make conditional panel in ui
    #calculate pastaPassed as 
    res=sapply(pastaFields, function(x) input[[x]])
    if (all(res)) 
      div(class="alert alert-success",
        helpText("Patient meets all criteria, now ring 021-XXX-XXXX for final confirmation with oncall neurologist."),
        radioButtons("radNeurologistAccepted", "Was the patient accepted by the oncall neurologist?", choices=c("Yes","No"), width="100%"),
        helpText("If the patient is accepted by the oncall neurologist transport patient directly to ACH resus. If not accepted transfer to nearest ED as usual."),
        datetimeInput("pastaDepartSceneTime", "Depart Scene Date and Time"))
    else
      div(class="alert alert-warning",
        p("Patient must meet all criteria above. If patient did not meet all criteria transfer to nearest ED as usual."))
    
  })
  
  # CLOCKS
  # =============================
  
  # update clocks after NHI change
  observe({
    if (input$NHI != "") {
      # id="StrokeOnsetTime"
      # mydate = input[[paste0(id,"_date")]]
      # mytime = strftime(input[[paste0(id,"_time")]], format="%H:%M")
      # x = parse_date_time(paste0(mydate," ",mytime), "Ymd HM", tz="Pacific/Auckland")
      # elapsedmins = difftime(now(tzone="Pacific/Auckland"), x, units="mins")
      # print(mydate)
      # print(mytime)
      # print(x)
      # print(now(tzone="Pacific/Auckland"))
      # print(elapsedmins)
      
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
  
  output$onsetGage = renderDkjustgage({
    dkjustgage(getElapsedTime("StrokeOnsetTime"),min=0,max=60)
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
