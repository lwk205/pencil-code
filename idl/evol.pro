;;;;;;;;;;;;;;;;;;;;
;;;   evol.pro   ;;;
;;;;;;;;;;;;;;;;;;;;

;;;
;;;  Author: wd (Wolfgang.Dobler@ncl.ac.uk)
;;;  Date:   12-Nov-2001
;;;
;;;  Description:
;;;   Time evolution (from n.dat).

default, nfile, datatopdir + '/n.dat'

default, oldfile, ''
default, oldmtime, 0

close,1
openr,1,nfile
fs = fstat(1)
close,1
mtime = fs.mtime

;; Re-read file only if it has changed
if ((nfile ne oldfile) or (mtime gt oldmtime)) then begin
  print,'Reading data'
  data = input_table(nfile)
  oldmtime = mtime
  oldfile = nfile
endif

tt = reform(data[1,*])
;
urms = reform(data[2,*])
umax = reform(data[3,*])
;
divurms = reform(data[11,*])
divumax = reform(data[12,*])
;
rmean = reform(data[8,*])
rrms  = reform(data[9,*])
rmax  = reform(data[10,*])

save_state

!p.multi=[0,2,2]

;; Velocity
yr = minmax([0,umax,urms])
plot, tt, urms, $
    YRANGE=yr, YSTYLE=3, $
    TITLE='!6Velocity!X', $
    XTITLE='!8t!X', YTITLE='!8u!X'
oplot, tt, umax, LINE=2
esrg_legend, $
    ['!6rms!X', '!6max!X'], $
    LINE=[0,2], SPOS='tl', /BOX


;; div u
yr = minmax([divumax,divurms])
plot, tt, divurms, $
    YRANGE=yr, YSTYLE=3, $
    TITLE='!6div !17u!X', $
    XTITLE='!8t!X', YTITLE='!17div !8u!X'
oplot, tt, divumax, LINE=2

;; ln rho
yr = minmax([0,rmean,rmax,rrms])
plot, tt, rrms, $
    YRANGE=yr, YSTYLE=3, $
    TITLE='!6log-density!X', $
    XTITLE='!8t!X', YTITLE='!6ln !7r!X'
oplot, tt, rmean, LINE=1
oplot, tt, rmax, LINE=2

restore_state

end
; End of file evol.pro
