library(shiny)
library(shinyTime)

shinyServer(function(input, output, session) {
  
  vals = reactiveValues()
  
  getPatients = reactive({
    if (is.null(vals[["patients"]])) {
      DF = read.csv("data/patients.csv", stringsAsFactors = F)
      DF$onsetDate = ymd(DF$onsetDate)
    }
    else
      DF = vals[["patients"]]
    
    vals[["patients"]] = DF
    DF
  })
  
  getCurrentPatients = reactive({
    getPatients() %>% 
      filter(completed==F)
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
      textInput("txtNHI", "NHI", value=""),
      selectInput("txtLocation", "Location", choices=c("Unknown","PreHospital","Resus/CT", "Angio/PACU", "Wd63","DCC","Other")),
      dateInput("dateOnset", "Symptom Onset Date"),
      timeInput("timeOnset","Symptom Onset Time",seconds=F),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("btnNewPatientOK", "OK")
      )
    ))
  })
  
  # update current NHI selection following creation of a new patient
  observe({
    updateSelectInput(session, "selCurrentNHI", choices=vals$patients$NHI)
  })
  
  observe({
    # if (input$selCurrentNHI != "")
      runjs("$('#onsetTimer').FlipClock({});")
  })
  
  # automatic calculation of LAMS Total
  observe({
    lamsFace = sum(as.numeric(c(input$radLAMSArm, input$radLAMSFace, input$radLAMSGrip)))
    updateCheckboxInput(session, "chkLAMS", value=(lamsFace>2))
  })
  
  output$htmlPASTAResult = renderUI({
    pastaFields = c("chkAfterhours","chkWTK","chkAge","chkFunction","chkBSL","chkGCS","chkOnsetTime","chkLAMS")
    res=sapply(pastaFields, function(x) input[[x]])
    if (all(res)) 
      tagList(
        helpText("Patient meets all criteria, now ring 021-XXX-XXXX for final confirmation with oncall neurologist."),
        radioButtons("radNeurologistAccepted", "Was the patient accepted by the oncall neurologist?", choices=c("Yes","No"), width="100%"),
        helpText("If the patient is accepted by the oncall neurologist transport patient directly to ACH resus. If not accepted transfer to nearest ED as usual."))
    else
      tagList(helpText("Patient must meet all criteria above. If patient did not meet all criteria transfer to nearest ED as usual."))
  })
  
  observeEvent(input$btnNewPatientOK, {
    if (!is.null(input$txtNHI)) {
      vals$NHI = input$txtNHI
      vals$patients = rbind(vals$patients, data.frame(NHI=input$txtNHI, location=input$txtLocation, onsetDate=input$dateOnset, onsetTime=strftime(input$timeOnset,"%R")))
      write.csv(getPatients(), file="data/patients.csv", row.names=F)
      removeModal()
    }
  })

})
