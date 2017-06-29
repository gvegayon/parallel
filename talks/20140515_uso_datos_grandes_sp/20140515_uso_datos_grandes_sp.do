clear all
set more off
set trace off

texdoc init 20140515_uso_datos_grandes_sp.tex, replace

/*tex
\documentclass{beamer}[10pt]
\usepackage{etex}
\reserveinserts{28}

\usetheme{spensiones}

\usepackage{stata}
\usepackage{amsmath}

\title{Gesti\'on de datos grandes utilizando {\tt parallel}}
\author[GGV]{George G. Vega\\ {\tt \scriptsize gvega@spensiones.cl}}
\institute[SPensiones]{Chilean Pension Supervisor}

\begin{document}

\frame{\maketitle}

\begin{frame}
\frametitle{Gesti\'on de datos grandes}

\begin{itemize}
\item Revisaremos el uso del subcomando de parallel -{\tt parallel append}-.
\item Este comando permite manipular bases de datos fragmentadas de forma paralela.
\item La idea es poder preprocesar cada fragmento por separado antes de unirlo.
\item Incluye listado de archivos de manera sencilla.
\item Permite pasar programas propios (es la idea principal).
\end{itemize}

\end{frame}

\begin{frame}
\frametitle{C\'omo funciona}

\begin{enumerate}
\item -{\tt parallel}- verifica que la lista de archivos exista.
\item El algoritmo distribuye los $N$ archivos en grupos de acuerdo al n\'umero
de procesadores a utilizar.
\item Cada archivo es abierto y luego es se ejecuta la rutina que el usuario
determin\'o.
\item Cada archivo es comprimido y luego se almacena en una carpeta temporal.
\item Una vez que todos los archivos fueron procesados, -{\tt parallel}-
los une con el comando -{\tt append}-.
\end{enumerate}
\end{frame}

\begin{frame}[fragile]
\frametitle{Configuracion inicial}
\begin{verbatim}
// Limpiando espacio de trabajo
clean all
set more off
set trace off

// Numero de procesadores 
parallel setclusters 8

// Listado de macros (se recomienda usar globales)
global bda ~/../shared_bd/bases/bda/bases_stata
global carpeta ~/parallel/presentaciones/20140515_uso_datos_grandes_sp
\end{verbatim}
\end{frame}

tex*/

/*tex
\begin{frame}
\frametitle{Ejemplos}
\framesubtitle{Uso de parallel como prefijo}
\footnotesize
tex*/

texdoc stlog setup
/* Config */
sysuse auto
parallel setclusters 2

/* Ordenando datos*/
sort rep78
texdoc stlog close
/*tex
\end{frame}

\begin{frame}[fragile]
\frametitle{Ejemplos}
\framesubtitle{Uso de parallel como prefijo (cont. 1)}
\footnotesize
\begin{verbatim}
. /* Calculo de media by */
. parallel, by(rep78): by rep78: egen maxp=max(price)
Parallel Computing with Stata (by GVY)
Clusters   : 2
pll_id     : dzor2cr328
Running at : f:\parallel\presentaciones\20140515_uso_datos_grandes_sp
Note: randtype = datetime
Waiting for the clusters to finish...
cluster 0001 has finished without any error...
cluster 0002 has finished without any error...
-------------------------------------------------------------------------------
Enter -parallel seelog #- to checkout logfiles.
-------------------------------------------------------------------------------
\end{verbatim}

Podemos ver que fue lo que ocurri\'o...

\begin{verbatim}
parallel seelog 1
\end{verbatim}

\end{frame}
tex*/

log using seelog1.txt, replace text
parallel seelog 1
log close

/*tex 

\begin{frame}[fragile]
\frametitle{Ejemplos}
\framesubtitle{Uso con comandos personalizados}

Crearemos un programa que utilizaremos dentro de parallel

tex*/

texdoc stlog prefix_pers1
program def miprog
	collapse (mean) price, by(rep78) fast
	ren price precio_prom_rep78
end
texdoc stlog close

/*tex

Luego, este programa podemos ejecutarlo como:

\begin{verbatim}
parallel, by(rep78) programs(miprog) : miprog
\end{verbatim}

\end{frame}

\begin{frame}[fragile]
\frametitle{Ejemplos}
\framesubtitle{Comando {\tt parallel append}}

La sintaxis de parallel append es bastante intuitiva. Solo basta
con indicarle un grupo de archivos junto con un comando/programa
a ejecutar

\small
\begin{verbatim}
parallel append arch1.dta arch2.dta arch3.dta arch4.dta, ///
    do(collapse (mean) price, by(rep78))
\end{verbatim}

\begin{verbatim}
parallel append , ///
    do(collapse (mean) price, by(rep78)) ///
    exp("arch%g.dta, 1/4")
\end{verbatim}
\end{frame}

\end{document}
tex*/

texdoc close
