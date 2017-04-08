library(shiny)
library(htmltools)
library(lubridate)

hiddenTextInput = function (inputId, value = "")
{
  tags$input(
    id = inputId,
    type = "text",
    class = "form-control",
    value = value,
    style = "display:none;"
  )
}

textButtonInput = function(inputid, inputlabel, buttonid, buttonlabel, value="", width=NULL, placeholder=NULL) {
  div(class="form-group shiny-input-container",
      tags$label(`for`=inputid, inputlabel),
      div(class="input-group", style="width: 18em;",
          tags$input(id=inputid, type="text", class="form-control", value=value, placeholder=placeholder),
          span(class="input-group-btn",
               actionButton(buttonid, buttonlabel))
      )
  )
}

titledPanel = function (title, ...) {
  div(class="header-panel", div(class="panel panel-primary",
                                div(class="panel-heading",
                                    h3(title, class="panel-title")
                                ),
                                div(class="panel-body", ...)
  ))
}

# datetimeDependency = htmlDependency("datetimeDependency", version="4.17.47",
#                                     src = "www",
#                                     script = c("moment.min.js", "bootstrap-datetimepicker.min.js", "datetime-binding.js"),
#                                     stylesheet = "bootstrap-datetimepicker.min.css")
# 
# datetimeInput = function (inputId, label, value = "", width = NULL, placeholder = NULL) 
# {
#   value <- restoreInput(id = inputId, default = value)
#   tagList(
#     tags$div(class = "form-group shiny-input-container",
#              tags$label(label, `for` = inputId),
#              tags$div(class="input-group date datetimepicker", id=paste0(inputId,"_datetimepicker"),  
#                       tags$input(id = inputId, type = "text", class = "form-control"),
#                       tags$span(class="input-group-addon", 
#                                 tags$span(class="glyphicon glyphicon-calendar")
#                       )
#              )
#     ), datetimeDependency
#   )
# }
  
clockjs = HTML("
<script>
var clock=[];
$(document).ready(function() {
    var i = 0;
    $('.flipclockdiv').each(function() {
        clock[i] = $(this).FlipClock({
            clockFace: 'DailyCounter',
            autoStart: false,
            showSeconds: false});
        i++;
    });
});
</script>
")

flipclockDependency = htmlDependency("flipclockDependency", version="1",
                                    src = "www",
                                    script = "flipclock.js",
                                    stylesheet = c("flipclock.css", "flipclockhack.css"),
                                    head = clockjs)

flipclock = function(id, label) {
  div(style="text-align: center",
    h4(label),
    div(id=id, class="flipclockdiv", style="zoom:0.4;display:inline-block;width:auto;"), flipclockDependency)
}

datetimeInput = function(inputId, label, datevalue = NULL, datemin = NULL, datemax = NULL,
            dateformat = "yyyy-mm-dd", datestartview = "month", dateweekstart = 0,
            language = "en", datewidth = NULL, timevalue = NULL, timeseconds=F) {

  if (inherits(datevalue, "Date")) datevalue <- format(datevalue, "%Y-%m-%d")
  if (inherits(datemin, "Date"))   datemin <- format(datemin, "%Y-%m-%d")
  if (inherits(datemax, "Date"))   datemax <- format(datemax, "%Y-%m-%d")
  if (is.null(datevalue)) datevalue=NA

  if (is.null(timevalue)) {
    value_list = list(hour=NA, min=NA, sec=NA)
    #timevalue <- shinyTime:::getDefaultTime()
  }
  else
    value_list <- shinyTime:::parseTimeFromValue(timevalue)
  timestyle <- "width: 8ch"
  input.class <- "form-control"
  
  tags$div(id = inputId, class = "form-group shiny-input-container",
    # shiny:::controlLabel(inputId, label),
      tags$label(class="control-label", 'for'=paste0(inputId,"_date"), style="width:350px", label),

      tags$div(id = paste0(inputId, "_date"), class="shiny-date-input", style="display:inline-block; vertical-align:top; width:100px; ",
        tags$input(type = "text", class = "form-control",
         `data-date-language` = language, `data-date-week-start` = dateweekstart,
         `data-date-format` = dateformat, `data-date-start-view` = datestartview,
         `data-min-date` = datemin, `data-max-date` = datemax, `data-initial-date` = datevalue)),

      tags$div(id = paste0(inputId,"_time"), class = "my-shiny-time-input", style="display:inline-block;",
        tags$div(class = "input-group",
          tags$input(type = "number", min = "0", max = "23", step = "1", value = value_list$hour, style = timestyle, class = paste(c(input.class, "shinytime-hours"), collapse = " ")),
          tags$input(type = "number", min = "0", max = "59", step = "1", value = value_list$min, style = timestyle, class = paste(c(input.class, "shinytime-mins"), collapse = " ")),
          if (timeseconds) tags$input(type = "number", min = "0", max = "59", step = "1", value = value_list$sec, style = timestyle, class = paste(c(input.class, "shinytime-secs"), collapse = " ")),
          singleton(tags$head(tags$script(src = "shinyTime/input_binding_time.js")))
        )
      ),

      actionButton(paste0(inputId,"_now"), "Now", style="display:inline-block; vertical-align:top;")
  )
}

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
