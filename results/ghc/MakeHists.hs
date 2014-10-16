module MakeHists where

import Control.Monad (forM, forM_)
import Data.List (intersperse)
import Data.Map (Map, toList)
import System.Process (readProcess, callProcess)
import Text.Printf

import OrdZip
import Results

main :: IO ()
main = do
  makePlotsProp1NewConsts
  makeTableProp1NewConsts
  makePlotsProp2NewConsts
  makeTableProp2NewConsts

measurements = [
  ("test27_hand_50_2014-10-11", "Hand-written (size: 50)"),
  ("test17_hand_70_2014-10-11", "Hand-written (size: 70)"),
  ("test34_hand_90_2014-10-11", "Hand-written (size: 90)"),
  ("test18_redex_6_2014-10-11", "Redex (depth: 6)"),
  ("test15_redex_7_2014-10-11", "Redex (depth: 7)"),
  ("test22_redex_8_2014-10-11", "Redex (depth: 8)"),
  ("test23_redex_6_nopoly_2014-10-11", "Redex non-poly (depth: 6)"),
  ("test16_redex_7_nopoly_2014-10-11", "Redex non-poly (depth: 7)"),
  ("test24_redex_8_nopoly_2014-10-11", "Redex non-poly (depth: 8)")]

measurementsNewConsts = [
  ("test27_hand_50_2014-10-11", "Hand-written (size: 50)"),
  ("test17_hand_70_2014-10-11", "Hand-written (size: 70)"),
  ("test34_hand_90_2014-10-11", "Hand-written (size: 90)"),
  ("test18_redex_6_2014-10-11", "Redex (depth: 6)"),
  ("test15_redex_7_2014-10-11", "Redex (depth: 7)"),
  ("test22_redex_8_2014-10-11", "Redex (depth: 8)"),
  ("test40_redex_6_nopoly_2014-10-14", "Redex non-poly (depth: 6)"),
  ("test39_redex_7_nopoly_2014-10-14", "Redex non-poly (depth: 7)"),
  ("test37_redex_8_nopoly_2014-10-14", "Redex non-poly (depth: 8)")]

measurements2ex = [
  ("test32_2ex_hand_50_2014-10-11", "Hand-written (size: 50)"),
  ("test21_2ex_hand_70_2014-10-11", "Hand-written (size: 70)"),
  ("test33_2ex_hand_90_2014-10-11", "Hand-written (size: 90)"),
  ("test28_2ex_redex_6_2014-10-11", "Redex (depth: 6)"),
  ("test19_2ex_redex_7_2014-10-11", "Redex (depth: 7)"),
  ("test29_2ex_redex_8_2014-10-11", "Redex (depth: 8)"),
  ("test31_2ex_redex_6_nopoly_2014-10-11", "Redex non-poly (depth: 6)"),
  ("test20_2ex_redex_7_nopoly_2014-10-11", "Redex non-poly (depth: 7)"),
  ("test30_2ex_redex_8_nopoly_2014-10-11", "Redex non-poly (depth: 8)")]

measurements2exNewConsts = [
  ("test32_2ex_hand_50_2014-10-11", "Hand-written (size: 50)"),
  ("test21_2ex_hand_70_2014-10-11", "Hand-written (size: 70)"),
  ("test33_2ex_hand_90_2014-10-11", "Hand-written (size: 90)"),
  ("test28_2ex_redex_6_2014-10-11", "Redex (depth: 6)"),
  ("test19_2ex_redex_7_2014-10-11", "Redex (depth: 7)"),
  ("test29_2ex_redex_8_2014-10-11", "Redex (depth: 8)"),
  ("test42_2ex_redex_6_nopoly_2014-10-14", "Redex non-poly (depth: 6)"),
  ("test41_2ex_redex_7_nopoly_2014-10-14", "Redex non-poly (depth: 7)"),
  ("test38_2ex_redex_8_nopoly_2014-10-14", "Redex non-poly (depth: 8)"),
  ("test43_2ex_redex_10_nopoly_2014-10-14", "Redex non-poly (depth: 10)"),
  ("test44_2ex_redex_12_nopoly_2014-10-14", "Redex non-poly (depth: 12)")]

prefix = "data/"

makeHist mul muls f1 t1 = do
  doc <- here "DATA" "MakeHists.hs" [("file1", prefix ++ f1),            ("title1",t1),
                                     ("file2", prefix ++ f1 ++ "_ctrex"),("title2",t1 ++ " ctrex (*" ++ muls ++ ")"),
                                     ("out", prefix ++ "aggr2_" ++ f1), ("mul", show mul)]
  readProcess "gnuplot" [] doc

copyAggrs msm =
  forM_ (map fst msm) $ \n -> do
    callProcess "scp" ["ttitania:prg/terms-tmp/rundir/" ++ n ++ "/aggr", prefix ++ n ++ ".aggr"]

genAggr (f, t) = do
  callProcess "ssh" ["ttitania", "cd prg/terms-tmp/rundir/" ++ f ++ "; grep -h TimingInfo runTest.sh.o*|LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/palka/.local_inst/usr/lib ../../aggregate > aggr"]

getResults f = do
  s <- readFile f
  return (read s :: (TimingInfo, (Histogram Int, Histogram Int)))

printHistograms f o octr = do
  (timing, (Histogram h, Histogram hctr)) <- getResults f
  writeFile o    $ printForGnuplot 160 (toList h)
  writeFile octr $ printForGnuplot 160 (toList hctr)

roughPrint :: Double -> String
roughPrint x
  | x < 10         = printf "%.1f" x
  | x < 1000       = printf "%.0f" x
  | x < 10000      = printf "%.1fk" (x / 1000)
  | x < 1000000    = printf "%.0fk" (x / 1000)
  | x < 10000000   = printf "%.1fM" (x / 1000000)
  | x < 100000000  = printf "%.0fM" (x / 1000000)

oneIn s tot 0 = "$\\infty$"
oneIn s tot n = roughPrint (tot / fromIntegral n) ++ s

timingRow (f, t) = do
  (TimingInfo (RunTime gent gens)
              (RunTime cht chs),
   (Histogram h, Histogram hctr))
                       <- getResults (prefix ++ f ++ ".aggr")
  let total = sum $ map snd $ toList h
      nctr  = sum $ map snd $ toList hctr
  return $ row t (show total)
                 (oneIn "" (fromIntegral total) nctr)
                 (myprint (conv (gent + gens) / fromIntegral total))
                 (myprint (conv (cht + chs) / fromIntegral total))
                 (oneIn "" (conv (cht + chs + gent + gens)) nctr)
  where
  conv :: Integer -> Double
  conv n = fromIntegral (n `div` 1000000)
  myprint :: Double -> String
  myprint x
    | x < 0.1   = printf "%.3f" x
    | otherwise = printf "%.2f" x

timingRows msm = do
  rows <- forM msm timingRow
  return $ concat rows

makeGnuplotInputs (f, t) = do
  printHistograms (prefix ++ f ++ ".aggr") (prefix ++ f ++ ".dat") (prefix ++ f ++ "_ctrex.dat")

runGnuPlot mul muls (f, t) = do
  makeHist mul muls f t

makePlots mul muls msm = do
  forM_ msm makeGnuplotInputs
  forM_ msm (runGnuPlot mul muls)

make2ex = do
  copyAggrs measurements2ex
  makePlots 10000 "10k" measurements2ex

makePlotsProp1NewConsts = do
  --forM_ measurementsNewConsts genAggr
  --copyAggrs measurementsNewConsts
  makePlots 1000 "1k" measurementsNewConsts
  makePage "prop1_newconsts" measurementsNewConsts
  callProcess "pdflatex" ["prop1_newconsts.tex"]

makeTableProp1NewConsts = do
  r <- timingRows measurementsNewConsts
  table "table_prop1_newconsts" r
  tableDoc "table_prop1_newconsts" "table_prop1_newconsts_page" "25.5" "6"
  callProcess "pdflatex" ["table_prop1_newconsts_page.tex"]

makePlotsProp2NewConsts = do
  --forM_ measurements2exNewConsts genAggr
  --copyAggrs measurements2exNewConsts
  makePlots 10000 "10k" measurements2exNewConsts
  makePage "prop2_newconsts" measurements2exNewConsts
  callProcess "pdflatex" ["prop2_newconsts.tex"]

makeTableProp2NewConsts = do
  r <- timingRows measurements2exNewConsts
  table "table_prop2_newconsts" r
  tableDoc "table_prop2_newconsts" "table_prop2_newconsts_page" "26" "6.7"
  callProcess "pdflatex" ["table_prop2_newconsts_page.tex"]

chunk n [] = []
chunk n l  = l1 : chunk n l2
  where (l1, l2) = splitAt n l

spliceEvery n s l = concat $ intersperse [s] $ chunk n l

makePage name msm = do
  let plots = concat $ spliceEvery 3 "\\\\"
        [ "\\includegraphics{" ++ prefix ++ "aggr2_" ++ f ++ ".pdf}\n" | (f, _) <- msm ]
  page <- here "PAGE" "MakeHists.hs" [("plots", plots)]
  writeFile (name ++ ".tex") page

here tag file env = do
   txt <- readFile file
   let (_,_:rest) = span (/="{- "++tag++" START") (lines txt)
       (doc,_) = span (/="   "++tag++" END -}") rest
   return $ unlines $ map subst doc
   where
    subst ('$':'(':cs) = case span (/=')') cs of 
      (var,')':cs) -> maybe ("$("++var++")") id (lookup var env) ++ subst cs
      _ -> '$':'(':subst cs
    subst (c:cs) = c:subst cs
    subst "" = ""

{- DATA START
#set terminal svg size 800,600 fname 'Verdana' fsize 10
set terminal pdf size 6.4cm,4.8cm
#set terminal latex size 8cm,6cm color
set output '$(out).pdf'
set style data histogram
set style histogram cluster gap 1
set style fill solid noborder
set xrange [-1:120]
#set yrange [0:300000]
set yrange [0:60000]
plot '$(file1).dat' using 2 title '$(title1)' lt 7, '$(file2).dat' using ($2 * $(mul)) title '$(title2)' lt 1 with histogram
   DATA END -}

{- DATA2 START
#set terminal svg size 800,600 fname 'Verdana' fsize 10
set terminal pdf size 6.4cm,4.8cm
#set terminal latex size 8cm,6cm color
set output '$(out).pdf'
set style data histogram
set style histogram cluster gap 1
set style fill solid noborder
set xrange [-1:100]
set yrange [0:75000]
plot '$(file1).dat' using 2 title '$(title1)' lt 7, '$(file2).dat' using ($2 * 1000) title '$(title2)' lt 1 with histogram
   DATA2 END -}

{- PAGE START
\documentclass{article}
\usepackage[papersize={21cm, 16cm}, margin=0.5cm]{geometry}

\usepackage[pdftex]{graphicx}

\begin{document}

\noindent
$(plots)

\end{document}
   PAGE END -}

table o r = do
  doc <- here "TABLE" "MakeHists.hs" [("content", r)]
  writeFile (o ++ ".tex") doc

tableDoc tableFile docf hsize vsize = do
  doc <- here "TABLEDOC" "MakeHists.hs" [("tablefile", tableFile),
                                         ("hsize", hsize),
                                         ("vsize", vsize)]
  writeFile (docf ++ ".tex") doc

row a b c d e f = (concat $ intersperse " & " [a, b, c, d, e, f]) ++ "\\\\\n"

rows = concat [
  row "Hand-written"        "?" "16k"       "0.008" "0.009"  "",
  row "Redex"               "?" "$\\infty$"  "0.147" "0.007" "",
  row "Redex nonpoly"       "?" "710"       "?"     "?"      "",
  row "Redex large"         "?" "500k"      "5.58"  "0.0011" "",
  row "Redex large nonpoly" "?" "75"        "0.419" "0.0041" ""]

{- TABLE START
\begin{tabular}{llllll}
\toprule
Generator & Tot. gen. terms & Ctrex. per N terms & Time per term(s) & Time per term (comp.\ \& exec.) (s) & Tot. time per ctrex. (s) \\
\midrule
$(content)
\bottomrule
\end{tabular}
   TABLE END -}

{- TABLEDOC START
\documentclass{article}
\usepackage[papersize={$(hsize)cm, $(vsize)cm}, margin=0.5cm]{geometry}

\usepackage{booktabs}

\begin{document}

\input{$(tablefile)}

\end{document}
   TABLEDOC END -}
