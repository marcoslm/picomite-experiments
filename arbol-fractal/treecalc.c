/*
 * TreeCalc - USA ARRAYS DE SALIDA COMO STACK
 * Los arrays estaticos no funcionan en CSUB
 */
#include <stdint.h>
#include "csub/PicoCFunctions.h"

#define MAX_DEPTH 10
#define MAX_LINES 2047
#define SIN_TABLE_SIZE 360
#define FP_SHIFT 14
#define STACK_SIZE 24

/* Usamos el final de los arrays de salida como stack:
 * t_x1[2047..2070] = stk_x
 * t_y1[2047..2070] = stk_y  
 * t_x2[2047..2070] = stk_len
 * t_y2[2047..2070] = stk_ang
 * t_col[2047..2070] = stk_dep
 */
#define STK_BASE 2047

void TreeCalc(long long *params,
              long long *sin_table, long long *map,
              long long *t_x1, long long *t_y1, 
              long long *t_x2, long long *t_y2, long long *t_col,
              long long *t_width,
              long long *line_count) {
    
    int sp = 0, lc = 0;
    
    int cx = (int)params[0];
    int cy = (int)params[1];
    int growth_fp = (int)params[2];
    int angle_deg = (int)params[3];
    int wind_fp = (int)params[4];
    int spread_base = (int)params[5];
    int spread_mult = (int)params[6];
    int depth_mult = (int)params[7];
    int grosor_max = (int)params[8];
    
    /* Longitud inicial en pixeles */
    int init_len = growth_fp >> FP_SHIFT;
    
    if (init_len <= 0) {
        *line_count = 0;
        return;
    }
    
    /* Push inicial - usando arrays de salida como stack */
    t_x1[STK_BASE] = cx;
    t_y1[STK_BASE] = cy;
    t_x2[STK_BASE] = init_len;
    t_y2[STK_BASE] = angle_deg;
    t_col[STK_BASE] = 0;
    sp = 1;
    
    while (sp > 0 && lc < STK_BASE) {
        sp--;
        int sidx = STK_BASE + sp;
        int x = (int)t_x1[sidx];
        int y = (int)t_y1[sidx];
        int len = (int)t_x2[sidx];
        int ang = (int)t_y2[sidx];
        int depth = (int)t_col[sidx];
        
        /* mod360 - sin division */
        int idx = ang;
        while (idx >= SIN_TABLE_SIZE) idx -= SIN_TABLE_SIZE;
        while (idx < 0) idx += SIN_TABLE_SIZE;
        int cos_idx = idx + 90;
        while (cos_idx >= SIN_TABLE_SIZE) cos_idx -= SIN_TABLE_SIZE;
        
        /* sin/cos estan escalados x16384 */
        int sin_v = (int)sin_table[idx];
        int cos_v = (int)sin_table[cos_idx];
        
        /* Calcular punto final */
        int nx = x + ((cos_v * len) >> FP_SHIFT);
        int ny = y + ((sin_v * len) >> FP_SHIFT);
        
        /* Clamp para evitar lineas locas */
        if (nx < -500) nx = -500;
        if (nx > 820) nx = 820;
        if (ny < -500) ny = -500;
        if (ny > 740) ny = 740;
        
        /* Guardar linea en la parte baja de los arrays */
        t_x1[lc] = x;
        t_y1[lc] = y;
        t_x2[lc] = nx;
        t_y2[lc] = ny;
        t_col[lc] = map[depth + 1];
        
        /* Grosor progresivo: maximo en tronco (depth=0), minimo 1 */
        int w = grosor_max - depth;
        if (growth_fp > 500000) { 
            if (depth > 4) w = depth; 
            /*if (depth > 4) w = (growth_fp / 100000);*/
        }
        if (w < 1) w = 1;
        if (w > 6) w = 6; /* En un punto del crecimiento, hacemos que la copa tenga líneas más anchas */
        t_width[lc] = w;
        
        lc++;
        
        if (depth < MAX_DEPTH && sp < STACK_SIZE - 2) {
            /* Reducir longitud: 72% */
            int new_len = (len * 184) >> 8;
            if (new_len < 1) new_len = 1;
            
            int spread = spread_base + ((wind_fp * spread_mult) >> FP_SHIFT);
            int wind_d = ((wind_fp * depth_mult) >> FP_SHIFT) * depth;
            
            /* Rama derecha */
            int pidx = STK_BASE + sp;
            t_x1[pidx] = nx;
            t_y1[pidx] = ny;
            t_x2[pidx] = new_len;
            t_y2[pidx] = ang + spread + wind_d;
            t_col[pidx] = depth + 1;
            sp++;
            
            /* Rama izquierda */
            pidx = STK_BASE + sp;
            t_x1[pidx] = nx;
            t_y1[pidx] = ny;
            t_x2[pidx] = new_len;
            t_y2[pidx] = ang - spread + wind_d;
            t_col[pidx] = depth + 1;
            sp++;
        }
    }
    
    /* Limpiar zona de stack para que LINE batch no dibuje basura */
    /* Lineas de longitud 0 con color del cielo (map[13] = cielo) */
    int sky_color = (int)map[13];
    for (int i = STK_BASE; i < STK_BASE + STACK_SIZE; i++) {
        t_x1[i] = 0;
        t_y1[i] = 0;
        t_x2[i] = 0;
        t_y2[i] = 0;
        t_col[i] = sky_color;
    }
    
    *line_count = lc;
}
