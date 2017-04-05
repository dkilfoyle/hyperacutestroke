library(shiny)
library(htmltools)

titledPanel = function (title, ...) {
  div(class="header-panel", div(class="panel panel-primary",
                                div(class="panel-heading",
                                    h3(title, class="panel-title")
                                ),
                                div(class="panel-body", ...)
  ))
}

datetimeDependency = htmlDependency("datetimeDependency", version="4.17.47",
                                    src = "www",
                                    script = c("moment.min.js", "bootstrap-datetimepicker.min.js"),
                                    stylesheet = "bootstrap-datetimepicker.min.css",
                                    head = HTML("<script>$(function() { $('.datetimepicker').datetimepicker({format: 'DD/MM/YYYY HH:mm', useCurrent: true, allowInputToggle: true}); })</script>")
)

datetimeInput = function (inputId, label, value = "", width = NULL, placeholder = NULL) 
{
  value <- restoreInput(id = inputId, default = value)
  tagList(
    tags$div(class = "form-group shiny-input-container",
             tags$label(label, `for` = inputId),
             tags$div(class="input-group date datetimepicker",  
                      tags$input(id = inputId, type = "text", class = "form-control"),
                      tags$span(class="input-group-addon", 
                                tags$span(class="glyphicon glyphicon-calendar")
                      )
             )
    ), datetimeDependency
  )
}

flipclockDependency = htmlDependency("flipclockDependency", version="1",
                                    src = "www",
                                    script = "flipclock.js",
                                    stylesheet = "flipclock.css",
                                    head = HTML("<script>$(function() { $('.flipclockdiv').each(function(){ $(this).FlipClock({autoStart: false}); }); });</script>")
)

flipclock = function(id, label) {
  div(style="text-align: center",
    h4(label),
    div(id=id, class="flipclockdiv", style="zoom:0.5;display:inline-block;width:auto;"), flipclockDependency)
}