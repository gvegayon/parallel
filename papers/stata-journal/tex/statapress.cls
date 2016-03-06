%%
%% This is file `statapress.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% statapress.dtx  (with options: `statapress')
%% ===========================================================================
%% LaTeX 2e document class for Stata Press books
%% 
%% Copyright 2001--2006 StataCorp LP
%% 4905 Lakeway Drive
%% College Station, Texas 77845 USA
%% http://www.stata.com
%% stata@stata.com
%% 
%% Some macros and environments are modified versions of those given in
%% classes.dtx v1.4a 1999/01/07, copyrighted by The LaTeX3 Project.
%% 
%% \CharacterTable
%%  {Upper-case    \A\B\C\D\E\F\G\H\I\J\K\L\M\N\O\P\Q\R\S\T\U\V\W\X\Y\Z
%%   Lower-case    \a\b\c\d\e\f\g\h\i\j\k\l\m\n\o\p\q\r\s\t\u\v\w\x\y\z
%%   Digits        \0\1\2\3\4\5\6\7\8\9
%%   Exclamation   \!     Double quote  \"     Hash (number) \#
%%   Dollar        \$     Percent       \%     Ampersand     \&
%%   Acute accent  \'     Left paren    \(     Right paren   \)
%%   Asterisk      \*     Plus          \+     Comma         \,
%%   Minus         \-     Point         \.     Solidus       \/
%%   Colon         \:     Semicolon     \;     Less than     \<
%%   Equals        \=     Greater than  \>     Question mark \?
%%   Commercial at \@     Left bracket  \[     Backslash     \\
%%   Right bracket \]     Circumflex    \^     Underscore    \_
%%   Grave accent  \`     Left brace    \{     Vertical bar  \|
%%   Right brace   \}     Tilde         \~}
%%
\NeedsTeXFormat{LaTeX2e}[1996/06/01]
\ProvidesClass{statapress}
  [2008/06/04 v1.17
 Stata Press Book document class]
\def\sp@Warning#1{\ClassWarning{statapress}{#1}}
\def\sp@WarningNoLine#1{\ClassWarningNoLine{statapress}{#1}}
\def\sp@Info#1{\typeout{#1}\ClassInfo{statapress}{#1}}
\def\sp@opt@fleqn{}
\DeclareOption{fleqn}{\def\sp@opt@fleqn{fleqn}}
\def\sp@opt@open{openright}
\DeclareOption{openany}{\def\sp@opt@open{openany}}
\DeclareOption{noopenany}{\relax}
\DeclareOption{openright}{\relax}
\newif\ifsp@opt@bib
\sp@opt@bibtrue
\DeclareOption{bib}{\relax}
\DeclareOption{nobib}{\sp@opt@bibfalse}
\DeclareRobustCommand\em%
{\@nomath\em \ifdim \fontdimen\@ne\font >\z@ \upshape \else \slshape \fi}
\newif\ifsp@opt@fancy
\DeclareOption{fancy}{\sp@opt@fancytrue}
\DeclareOption{nofancy}{\sp@opt@fancyfalse}
\def\sp@opt@ptsize{10pt}
\DeclareOption{10pt}{\relax}
\DeclareOption{11pt}{\def\sp@opt@ptsize{11pt}}
\DeclareOption{12pt}{\def\sp@opt@ptsize{12pt}}
\let\efinalopt=\sp@undefined
\let\finalopt=\sp@undefined
\DeclareOption{default}{\relax}
\DeclareOption{final}{
  \sp@opt@fancytrue
  \let\finalopt=\relax
}
\DeclareOption{efinal}{
  \sp@opt@fancytrue
  \let\efinalopt=\relax
}
\DeclareOption*{\sp@Warning{{\CurrentOption} is not a valid option}}
\ExecuteOptions{default}
\ProcessOptions\relax
\PassOptionsToClass{\sp@opt@ptsize,\sp@opt@open,\sp@opt@fleqn}{book}
\LoadClass{book}
\RequirePackage{hyperref}% no date
\def\urlprefix{\relax}
\def\url#1{#1}
\RequirePackage{color}% no date
\ifsp@opt@fancy
  \RequirePackage{fancyhdr}% no date
  \renewcommand{\headrulewidth}{0pt}
\fi
\ifsp@opt@bib
  \RequirePackage{natbib}[1999/05/28]
  \bibpunct{(}{)}{;}{a}{}{,}
\fi
\RequirePackage{makeidx,showidx}
\RequirePackage{multind}
\def\printindex#1#2{%
  \columnseprule \z@ \columnsep 35pt%
  \clearpage%
  \if@openright%
    \thispagestyle{empty}%
    \cleardoublepage%
  \fi%
  \thispagestyle{empty}%
  \twocolumn[{\vspace*{56pt}\huge\sffamily\bfseries #2\vskip20pt}]%
  \markboth{#2}{#2}%
  \addcontentsline{toc}{index}{\numberline{}#2}%
  \@input{#1.ind}%
}
\def\indexspace{\par \vskip 12\p@ \@plus5\p@ \@minus3\p@\relax}
\def\std@tfill{\cleaders\hbox to.44em{\hss .\hss}\hskip .88em plus 1fill}%
\def\dotfil{\leaders\hbox to.44em{\hss .\hss}\hfil}%
\def\stdotfill{%
  \unskip\std@tfill\penalty500\strut%
  \nobreak%
  \dotfil\ignorespaces%
}
\def\spAuthorIndex{%
  \cleardoublepage%
  \printindex{author}{Author index}%
  \thispagestyle{empty}%
}
\def\spSubjectIndex{%
  \cleardoublepage
  \printindex{subject}{Subject index}
  \thispagestyle{empty}
}
\def\listfigurename{Figures}
\renewcommand{\listoffigures}{%
  \chapter*{\listfigurename}%
  \markboth{\listfigurename}{\listfigurename}%
  \addcontentsline{toc}{preface}{\numberline{}List of figures}%
  \begingroup
    \hyphenpenalty=10000
    \@starttoc{lof}%
  \endgroup
}
\newif\ifsp@appendix
\newdimen\digitwidth
\newdimen\appdigitwidth
\setbox0=\hbox{0}
\digitwidth=\wd0
\appdigitwidth=2\digitwidth
\setbox0=\hbox{A}
\advance\appdigitwidth by-\wd0
\def\spacethefigure{%
  \ifsp@appendix%
    \kern\appdigitwidth%
  \else%
    \ifnum\thechapter<10%
      \kern\digitwidth%
    \fi%
  \fi%
  \thefigure%
}
\def\spacethetable{%
  \ifsp@appendix%
    \kern\appdigitwidth%
  \else%
    \ifnum\thechapter<10%
      \kern\digitwidth%
    \fi%
  \fi%
  \thetable%
}
\long\def\@caption#1[#2]#3{%
  \par
  \addcontentsline{\csname ext@#1\endcsname}{#1}%
    {\protect\numberline{\csname spacethe#1\endcsname}%
      {\ignorespaces #2}}%
  \begingroup
    \@parboxrestore
    \if@minipage
      \@setminipage
    \fi
    \normalsize
    \@makecaption{\csname fnum@#1\endcsname}%
      {\ignorespaces #3}\par
  \endgroup}
\def\listtablename{Tables}
\renewcommand{\listoftables}{%
  \chapter*{\listtablename}%
  \markboth{\listtablename}{\listtablename}%
  \addcontentsline{toc}{preface}{\numberline{}List of tables}%
  \begingroup
    \hyphenpenalty=10000
    \@starttoc{lot}%
  \endgroup
}
\def\contentsname{Contents}
\renewcommand{\tableofcontents}{%
  \chapter*{\contentsname}%
  \markboth{\contentsname}{\contentsname}%
  \begingroup
    \hyphenpenalty=10000
    \@starttoc{toc}%
  \endgroup
}
\setcounter{tocdepth}{3}
\newcommand{\spthisheadings}[6]{%
  \ifsp@opt@fancy
    \thispagestyle{fancy}
    \sp@fancyheadings{#1}{#2}{#3}{#4}{#5}{#6}
  \else
    \thispagestyle{myheadings}
    \sp@myheadings{#1}{#2}{#3}{#4}{#5}{#6}
  \fi
}
\newcommand{\sp@headings}[6]{%
  \ifsp@opt@fancy
    \sp@fancyheadings{#1}{#2}{#3}{#4}{#5}{#6}
  \else
    \sp@myheadings{#1}{#2}{#3}{#4}{#5}{#6}
  \fi
}
\newcommand{\sp@fancyheadings}[6]{%
  \lhead{#1}
  \chead{#2}
  \rhead{#3}
  \lfoot{#4}
  \cfoot{#5}
  \rfoot{#6}
}
\newcommand{\sp@myheadings}[6]{%
  \renewcommand{\ps@myheadings}{%
    \renewcommand{\@oddhead}{{#1\hfil#2\hfil#3}}
    \renewcommand{\@evenhead}{{#3\hfil#2\hfil#2}}
    \renewcommand{\@oddfoot}{{#4\hfil#5\hfil#6}}%
    \renewcommand{\@evenfoot}{{#6\hfil#5\hfil#4}}%
  }
}
\sp@headings%
  {}{}{\protect\thepage}% head
  {}{}{}% foot
\newdimen\bibindent
\setlength\bibindent{1.5em}
\def\bibname{References}
\def\bibsection{\section{\bibname}}
\setlength{\parskip}{0.5\baselineskip}
\renewcommand{\labelenumii}{\theenumii.}
\renewcommand{\@makefntext}[1]{%
  \hangindent=1.8em\hangafter=1\noindent%
  \makebox[1.8em][r]{\mbox{$\@thefnmark$.\ }}#1}
\endinput
%%
%% End of file `statapress.cls'.
