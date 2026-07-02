# The following code is adapted from Stephan Kolassa:
#https://stats.stackexchange.com/questions/299712/what-are-the-shortcomings-of-the-mean-absolute-percentage-error-mape

mm <- 1
ss.sq <- 1

set.seed(5)
actuals <- rlnorm(100,meanlog=mm,sdlog=sqrt(ss.sq))

output_file <- "output/mape_shortcomings.pdf"
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
pdf(output_file, width = 8, height = 4)

opar <- par(mar=c(3,2,0,0)+.1)
on.exit({
  par(opar)
  dev.off()
}, add = TRUE)
    plot(actuals,type="o",pch=21,cex=0.8,bg="black",xlab="",ylab="",xlim=c(0,150))
    abline(v=101,col="gray")
    legend("topleft", legend=c("Min. expected MSE", "Min. expected MAE", "Min. expected MAPE"), col=c("blue", "green", "red"), lty=1)


    xx <- seq(0,max(actuals),by=.1)
    polygon(c(101+150*dlnorm(xx,meanlog=mm,sdlog=sqrt(ss.sq)),
      rep(101,length(xx))),c(xx,rev(xx)),col="lightgray",border=NA)

    min.Ese <- exp(mm+ss.sq/2)
    lines(c(101,150),rep(min.Ese,2),col="blue")
    
    min.Eae <- exp(mm)
    lines(c(101,150),rep(min.Eae,2),col="green")
    
    min.Eape <- exp(mm-ss.sq)
    lines(c(101,150),rep(min.Eape,2),col="red")