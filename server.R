library(shiny)
library(shinyTime)
library(dplyr)

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
    "StrokeOnsetTime",
    "CurrentLocation",
    "Completed",
    
    pastaFields,
    lamsFields,
    "pastaNeurologist",
    "amboDepartSceneTime"
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
  
  
  
  observeEvent(input$btnNewPatientOK, {
    if (!is.null(input$newptNHI)) {
      vals$currentNHI = input$newptNHI
      vals$patients = rbind(getPatients(), newPatient(NHI = input$newptNHI, Location=input$newptLocation, StrokeOnsetTime = input$newptStrokeOnsetTime))
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
  
  observe({
    # if (input$selCurrentNHI != "")
      # runjs("$('#onsetTimer').FlipClock({});")
  })
  
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
  


})
