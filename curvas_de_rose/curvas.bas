' ---------------------------------------------------------
'  Animacion Curvas de Rose
'  por Marcos LM 2025
' ---------------------------------------------------------

OPTION EXPLICIT
OPTION DEFAULT INTEGER
MODE 5 

' Configuracion
CONST MAX_SEGS = 255
const MAX_SEGS_MINUS = MAX_SEGS - 1
CONST SHOW_FPS = 0

' Arrays Graficos
DIM INTEGER r_x1(MAX_SEGS), r_y1(MAX_SEGS)
DIM INTEGER r_x2(MAX_SEGS), r_y2(MAX_SEGS)
DIM INTEGER r_col(255)

' Vectores y tablas
DIM FLOAT BaseCos(MAX_SEGS), BaseSin(MAX_SEGS)
DIM FLOAT BaseAng(MAX_SEGS)

' Variables
DIM INTEGER cx = MM.HRES \ 2
DIM INTEGER cy = MM.VRES \ 2
DIM float scale = cy - 10
'dim float scale_s = 0.25

DIM FLOAT n = 2.0, d = 29.0
DIM FLOAT n_step = 0.00025, d_step = 0.002
DIM FLOAT k, r_geo, d_rad
DIM FLOAT deg2rad = 0.0174533

' Temporales
DIM INTEGER i, x_curr, y_curr, x_next, y_next
DIM INTEGER r_idx, g_idx, b_idx, rgb_val
DIM FLOAT rads
DIM INTEGER fps_val, fps_count, timer_sec

' Configurar Paleta
FOR i = 0 TO 255
  ' Calculamos el color arcoiris normal
  rads = (i / 255.0) * 6.283
  r_idx = 127 + 127 * SIN(rads)
  g_idx = 127 + 127 * SIN(rads + 2.09)
  b_idx = 127 + 127 * SIN(rads + 4.18)
  rgb_val = RGB(r_idx, g_idx, b_idx)
  
  IF i = 0 THEN
     MAP(0) = RGB(BLACK) ' fondo negro
  ELSE
     MAP(i) = rgb_val
  ENDIF
  
  r_col(i) = rgb_val
NEXT i
MAP SET

' Vectores Base
d_rad = d * deg2rad
FOR i = 0 TO MAX_SEGS
  k = i * d_rad
  BaseAng(i) = k
  BaseCos(i) = COS(k)
  BaseSin(i) = SIN(k)
NEXT i

FRAMEBUFFER CREATE
FRAMEBUFFER WRITE F



'  BUCLE PRINCIPAL
DO
  'FRAMEBUFFER WRITE F
  CLS

  x_curr = cx : y_curr = cy
  
  FOR i = 0 TO MAX_SEGS_MINUS
    r_geo = SIN(n * BaseAng(i+1)) * scale
    x_next = cx + r_geo * BaseCos(i+1)
    y_next = cy + r_geo * BaseSin(i+1)
    
    r_x1(i) = x_curr : r_y1(i) = y_curr
    r_x2(i) = x_next : r_y2(i) = y_next
    
    x_curr = x_next : y_curr = y_next
  NEXT i

  LINE r_x1(), r_y1(), r_x2(), r_y2(), 1, r_col()

  if SHOW_FPS then TEXT 0, 0, str$(fps_val)

  FRAMEBUFFER COPY F,N
  
  if SHOW_FPS then 
    INC fps_count
    IF TIMER - timer_sec >= 1000 THEN
      fps_val = fps_count : fps_count = 0 : timer_sec = TIMER
    ENDIF
  end if
  
  INC n, n_step
  IF n > 9.0 OR n < 2.0 THEN n_step = -n_step
  INC d, d_step

  'inc scale, scale_s
  'if scale > 119 or scale < 80 then scale_s = -scale_s
LOOP
