## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- echo=FALSE---------------------------------------------------------
library(MFCC)
ls("package:MFCC")

## ----fig.height = 2, fig.width = 7, fig.align = "center"-----------------
library(MFCC) #carregar pacote do MFCC
library(ggplot2) #biblioteca para gr�ficos

#Obter arquivo de �udio exemplo
sound.data <- MFCC::sound.data
#Com o pacote tuneR, pode-se carregar um arquivo do disco da seguinte forma: (descomentar abaixo)
#sound.data <- tuneR::readWave('audio.wav', from = 0, to = 3.5, units = "seconds")
sound <- sound.data@left #valores do arquivo de �udio
sample.rate <- sound.data@samp.rate #sample rate do arquivo de �udio

#Exibir arquivo de �udio
sound.time <- 0:(length(sound)-1)/sample.rate #tempo em segundos

#criar estrutura contendo o x e y do gr�fico
data.raw <- data.frame(x = sound.time, y = sound)

#Exibir gr�fico
p <- ggplot(data.raw, aes(x, y)) + geom_line() +
  xlab("Tempo (s)") + ylab("Amplitude") #+


## ---- fig.width = 7.25, fig.align = "center", echo = FALSE, message=FALSE----
plotly::ggplotly(p)

## ------------------------------------------------------------------------
fft.npoints <- 512 #n�meros de pontos considerados para o c�lculo da fft 
#help(nfft) #para mais informa��es
freq.lower <- 0 #frequ�ncia m�nima em hertz considerada
freq.upper <- sample.rate / 2 #frequ�ncia m�xima em hertz considerada
num.filters <- 40 #n�mero filtros considerados para o filterbank

## ----fig.height = 2, fig.width = 7, fig.align = "center"-----------------

emphasized_signal <- apply_preemphasis(sound, 0.97)

#criar estrutura contendo o x e y do gr�fico
data.emphasized <- data.frame(x = sound.time, y = emphasized_signal)

#Exibi��o
p <- ggplot(data.emphasized, aes(x, y)) + geom_line() +
  xlab("Tempo (s)") + ylab("Amplitude")

## ---- fig.width = 7.25, fig.align = "center", echo = FALSE, message=FALSE----
plotly::ggplotly(p)

## ---- echo = FALSE-------------------------------------------------------
fft.npoints <- 512 #n�meros de pontos considerados para o c�lculo da fft 
#help(nfft) #para mais informa��es
freq.lower <- 0 #frequ�ncia m�nima em hertz considerada
freq.upper <- sample.rate / 2 #frequ�ncia m�xima em hertz considerada
num.filters <- 40 #n�mero filtros considerados para o filterbank

#1.Dividir o sinal em short frames.
frames <- frame_the_signal(emphasized_signal, sample.rate)
frames <- apply_window_hamming(frames) #aplicar a fun��o de hamming para cada frame

#2.Para cada quadro, calcular o power spectrum
power.frames <- compute_power_spectrum(frames, n = fft.npoints)

#3.Aplicar o mel filterbank aos power spectra, somar a energia em cada filtro
fbanks <- compute_mel_filterbanks(freq.lower,freq.upper, num.filters, fft.npoints, sample.rate)
#Para calcular a energia do filter bank, multiplica-se cada filter bank com seus power spectrum.
filter.banks <- power.frames %*% t(fbanks)

#4. Obter o logaritmo de todas as filterbank energies
filter.banks[filter.banks == 0] <- .Machine$double.eps #substituir os zeros para evitar problemas com log
filter.banks <- 20 * log10(filter.banks)

#5. Obter a DCT do log das filterbank energies.
mfcc <- t(apply(filter.banks, 1, function(x) apply_dct(x)))

#6. Manter os coeficientes DCT 2-13, descartar o resto..
mfcc <- mfcc[, 2:13]

## ----fig.height = 2, fig.width = 7, fig.align = "center"-----------------

#Organizar dado para melhor visualiza��o
x <- seq(from = freq.lower, to = freq.upper, length.out = ncol(fbanks)) %>% rep(num.filters)
y <- t(fbanks)
y %<>% as.data.frame() %>% tidyr::gather()

data <- data.frame(x = x, values = y$value, filters = y$key)

#Exibir espectograma
p <- ggplot(data, aes(x, values, colour = filters)) +
  geom_line() + xlab("Frequ�ncia") + ylab("Amplitude") + theme(legend.position="none") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))

## ---- fig.width = 7.25, fig.align = "center", echo = FALSE, message=FALSE----
plotly::ggplotly(p)

## ----fig.height = 2, fig.width = 7, fig.align = "center"-----------------

#Organizar dado para melhor visualiza��o
fbanks.spec <- reshape2::melt(filter.banks)
fbanks.spec$Var1 <- fbanks.spec$Var1 / 100
fbanks.spec$Var2 <- fbanks.spec$Var2 / 10

#Exibir espectograma
p <- ggplot(fbanks.spec, aes(Var1,Var2)) + geom_raster(aes(fill = value)) +
  scale_fill_gradientn(colours = rainbow(10)) +
  xlab("Tempo (s)") + ylab("Frequ�ncia (kHz)") + ggtitle("Espectograma do sinal") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))


## ---- fig.width = 7.25, fig.align = "center", echo = FALSE, message=FALSE----
plotly::ggplotly(p)

## ----fig.height = 2, fig.width = 7, fig.align = "center"-----------------
#Aplicar o sinusoidal liftering aos MFCCs
mfcc.lift <- apply_lifter(mfcc)

#Organizar dado para melhor visualiza��o
mfccs.spec <- reshape2::melt(mfcc.lift)
mfccs.spec$Var1 <- mfccs.spec$Var1 / 100

#Espectograma do MFCCs
p <- ggplot(mfccs.spec, aes(Var1,Var2, fill=value)) + geom_raster(aes(fill = value)) +
  scale_fill_gradientn(colours = rainbow(10)) +
  xlab("Tempo (s)") + ylab("Coeficientes das MFCCs") + ggtitle("MFCCs") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))



## ---- fig.width = 7.25, fig.align = "center", echo = FALSE, message=FALSE----
plotly::ggplotly(p)

