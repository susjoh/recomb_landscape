#
# Simulation of recombination landscape
# Susan E. Johnston
# Started: 5th November 2015
#
#

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# 0. Set up working environment                                #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


library(ggplot2)
library(plyr)
library(data.table)

map <- read.table("data/soay_map.txt", header = T)

sapply(paste0("R/", dir("R")), source)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# 1. Define simulation parameters and sampling distributions   #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


generations <- 100
no.females <- 50
no.males <- 50
no.loci <- 100
no.offspring <- 2
no.founder.hap <- 100
male.sel.thresh <- 0.4
iterations <- 5
sampling.int <- 10


#~~ Create the sampling distrubutions

map.dist <- diff(map$cM.Position.Sex.Averaged[seq(1, nrow(map), sampling.int)])
map.dist <- map.dist[which(map.dist >= 0 & map.dist < 2)]
maf.info <- map$MAF

#~~ Create object for results

res.list.modifier.present <- list()
res.list.modifier.absent  <- list()

system.time({
  
  for(i in 1:iterations){
    
    print(paste("Running simulation", i))
    
#     xr1   <- sample(map.dist/100, replace = T, no.loci)
#     xr2   <- sample(map.dist/100, replace = T, no.loci)
#     xrhet <- (xr1 + xr2)/2

    xr1   <- sample(map.dist/100, replace = T, no.loci)
    xr2   <- xr1*2
    xrhet <- (xr1 + xr2)/2
    
    map.list <- list(xr1, xrhet, xr2)
    rm(xr1, xrhet, xr2)
    
    allele.freqs <- map$MAF
    allele.freqs <- sample(allele.freqs, no.loci)
    allele.freqs <- allele.freqs + (runif(no.loci) < 0.5)/2
    
    
    x1 <- createFounderObject(map.list = map.list, allele.freqs = allele.freqs, n.found.hap = no.founder.hap,
                              n.loci = no.loci, n.f = no.females, n.m = no.males, f.RS = no.offspring, f.RS.Pr = NULL)
    
    res.list.modifier.present[[i]] <- rbindlist(
      simPopulationResponse(map.list = map.list, allele.freqs = allele.freqs,
                             n.found.hap = no.founder.hap, n.loci = no.loci, 
                             n.f = no.females, n.m = no.males, f.RS = no.offspring, 
                             sel.thresh.f = 1, sel.thresh.m = male.sel.thresh,
                             modifier.found.freq = 0.4, n.generations = generations,
                             FounderObject = x1)$results)
    
    res.list.modifier.present[[i]]$Simulation <- i
    
    res.list.modifier.absent[[i]] <- rbindlist(
      simPopulationResponse(map.list = map.list, allele.freqs = allele.freqs,
                             n.found.hap = no.founder.hap, n.loci = no.loci, 
                             n.f = no.females, n.m = no.males, f.RS = no.offspring, 
                             sel.thresh.f = 1, sel.thresh.m = male.sel.thresh,
                             modifier.found.freq = 0, n.generations = generations,
                             FounderObject = x1)$results)
    
    res.list.modifier.absent[[i]]$Simulation <- i
  }
})

# save(res.list.modifier.present, res.list.modifier.absent, 
#      file = paste0("results/g", generations, "_it", iterations,  "_f", no.females, "_m", no.males, "_o", no.offspring,
#                    "_l", no.loci, "_msel", male.sel.thresh, ".Rdata"))




# load(paste0("results/g", generations, "_it", iterations,  "_f", no.females, "_m", no.males, "_o", no.offspring,
#             "_l", no.loci, "_msel", male.sel.thresh, ".Rdata"))

test <- rbind(cbind(Modifier.Start = 0.4, rbindlist(res.list.modifier.present)),
              cbind(Modifier.Start = 0  , rbindlist(res.list.modifier.absent)))

test$Simulation <- as.factor(test$Simulation)
test$Modifier.Start <- as.factor(test$Modifier.Start)
head(test)

df1 <- ddply(test, .(GEN, Modifier.Start, Simulation), summarise, MeanPHENO = mean(PHENO))

df3 <- ddply(test, .(GEN, Modifier.Start, Simulation), summarise, VarPHENO = var(PHENO))

setkey(test, GEN, Modifier.Start, Simulation)

testfunc <- function(vec) {sum(vec - 1)/(2*length(vec))}

df2 <- test[,list(MeanPHENO=mean(PHENO),
                  VarPheno = var(PHENO),
                  PopSize = length(PHENO),
                  Modifier.Freq = testfunc(modifier)),
            by=list(GEN, Modifier.Start, Simulation)] 

head(df2)
test


ggplot(df2, aes(GEN, MeanPHENO, col = Modifier.Start, group = interaction(Simulation, Modifier.Start))) + 
  geom_line()

ggplot(df2, aes(GEN, VarPheno, col = Modifier.Start, group = interaction(Simulation, Modifier.Start))) + 
  geom_line()

ggplot(df2, aes(GEN, PopSize, col = Modifier.Start, group = interaction(Simulation, Modifier.Start))) + 
  geom_line()

ggplot(df2, aes(GEN, Modifier.Freq, col = Modifier.Start, group = interaction(Simulation, Modifier.Start))) + 
  geom_line()



ggplot(df1, aes(GEN, MeanPHENO, col = Modifier.Start)) +
  geom_point(alpha = 0) +
  stat_smooth() +
  theme(axis.text.x  = element_text (size = 16, vjust = 1),
        axis.text.y  = element_text (size = 16, hjust = 1),
        strip.text.x = element_text (size = 16, vjust = 0.7),
        axis.title.y = element_text (size = 16, angle = 90, vjust = 1),
        axis.title.x = element_text (size = 16, vjust = 0.2),
        strip.background = element_blank()) +
  scale_colour_brewer(palette = "Set1") +
  labs(title = paste0("g", generations, "_it", iterations,  "_f", no.females, "_m", no.males, "_o", no.offspring,
                      "_l", no.loci, "_msel", male.sel.thresh))

beepr::beep()