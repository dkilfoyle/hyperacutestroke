library(dplyr)
library(reshape2)
library(ggplot2)

x=data.frame(
  kpi=c("Onset2Door","Door2CT","Door2Needle"),
  mins=c(120,15,75),
  target=c(60,10,60)
)

x = x %>% 
  mutate(intarget=pmin(mins,target)) %>% 
  mutate(outtarget = mins-intarget) %>% 
  select(intarget, outtarget, kpi) %>% 
  melt("kpi")

  ggplot(x, aes(kpi, value, fill=variable)) + 
    geom_col(show.legend=F) +
    xlab("") + ylab("mins") + coord_flip()
    
