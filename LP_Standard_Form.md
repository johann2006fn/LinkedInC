# Linear Programming Problems - Standard Form Conversion

## Problem (i)

**Objective Function:**
$$\text{Maximize: } Z = 3x_1 + 2x_2 + 5x_3$$

**Constraints:**
1. $x_1 + 2x_2 + x_3 \le 430$
2. $3x_1 + 2x_3 \ge 460$
3. $x_1 + 4x_2 \le 420$
   - $x_1, x_2, x_3 \ge 0$

**Conversion Steps:**
- **Constraint 1 ($\le$):** Add slack variable $s_1$.
- **Constraint 2 ($\ge$):** Subtract surplus variable $s_2$ and add artificial variable $A_1$ (required for an initial basic feasible solution).
- **Constraint 3 ($\le$):** Add slack variable $s_3$.

### Standard Form
$$\text{Maximize: } Z = 3x_1 + 2x_2 + 5x_3 + 0s_1 + 0s_2 + 0s_3 - MA_1$$

**Subject to:**
$$\begin{aligned}
x_1 + 2x_2 + x_3 + s_1 &= 430 \\
3x_1 + 2x_3 - s_2 + A_1 &= 460 \\
x_1 + 4x_2 + s_3 &= 420 \\
x_1, x_2, x_3, s_1, s_2, s_3, A_1 &\ge 0
\end{aligned}$$

---

## Problem (ii)

**Objective Function:**
$$\text{Minimise: } Z = 3x_1 - x_2 + 3x_4$$
*(where $x_2$ is unrestricted)*

**Constraints:**
1. $x_1 + 2x_2 + x_3 \le -430$
2. $3x_1 + 2x_3 \le 460$
3. $x_1 + 4x_2 \le 420$
   - $x_1, x_3, x_4 \ge 0$

**Conversion Steps:**
- **Objective:** Convert to Maximize $Z' = -Z = -3x_1 + x_2 - 3x_4$.
- **Unrestricted Variable:** Replace $x_2$ with $(x_2' - x_2'')$ where $x_2', x_2'' \ge 0$.
- **Constraint 1 ($\le -430$):** Multiply by $-1$ to make RHS positive: $-x_1 - 2x_2 - x_3 \ge 430$. Then add slack $s_1$ (per user instructions).
- **Constraints 2 & 3 ($\le$):** Add slack variables $s_2$ and $s_3$.

### Standard Form
$$\text{Maximize: } Z' = -3x_1 + (x_2' - x_2'') - 3x_4 + 0s_1 + 0s_2 + 0s_3$$

**Subject to:**
$$\begin{aligned}
-x_1 - 2(x_2' - x_2'') - x_3 + s_1 &= 430 \\
3x_1 + 2x_3 + s_2 &= 460 \\
x_1 + 4(x_2' - x_2'') + s_3 &= 420 \\
x_1, x_2', x_2'', x_3, x_4, s_1, s_2, s_3 &\ge 0
\end{aligned}$$

---

## Problem (iii)

**Objective Function:**
$$\text{Maximize: } Z = 2x_1 + 5x_2 + 3x_3$$

**Constraints:**
1. $x_1 + 2x_2 + x_3 \le 430$
2. $3x_1 + 2x_2 \ge 460$
3. $x_1 + 4x_2 \le 420$
   - $x_1, x_2, x_3 \ge 0$

**Conversion Steps:**
- **Constraints 1 & 3 ($\le$):** Add slack variables $s_1$ and $s_3$.
- **Constraint 2 ($\ge$):** Subtract surplus variable $s_2$ and add artificial variable $A_1$.

### Standard Form
$$\text{Maximize: } Z = 2x_1 + 5x_2 + 3x_3 + 0s_1 + 0s_2 + 0s_3 - MA_1$$

**Subject to:**
$$\begin{aligned}
x_1 + 2x_2 + x_3 + s_1 &= 430 \\
3x_1 + 2x_3 - s_2 + A_1 &= 460 \\
x_1 + 4x_2 + s_3 &= 420 \\
x_1, x_2, x_3, s_1, s_2, s_3, A_1 &\ge 0
\end{aligned}$$

---

## Problem (iv)

**Objective Function:**
$$\text{Minimise: } Z = 3x_1 - x_2 + 3x_4$$
*(where $x_2$ is unrestricted)*

**Constraints:**
1. $x_1 + 2x_2 + x_3 \le -430$
2. $3x_1 + 2x_3 \le 460$
3. $x_1 + 4x_2 \le 420$
   - $x_1, x_3, x_4 \ge 0$

**Conversion Steps:**
- **Objective:** Convert to Maximize $Z' = -Z = -3x_1 + x_2 - 3x_4$.
- **Unrestricted Variable:** Replace $x_2$ with $(x_2' - x_2'')$.
- **Constraint 1:** Multiply by $-1$ and add slack $s_1$.
- **Constraints 2 & 3:** Add slack variables $s_2$ and $s_3$.

### Standard Form
$$\text{Maximize: } Z' = -3x_1 + (x_2' - x_2'') - 3x_4 + 0s_1 + 0s_2 + 0s_3$$

**Subject to:**
$$\begin{aligned}
-x_1 - 2(x_2' - x_2'') - x_3 + s_1 &= 430 \\
3x_1 + 2x_3 + s_2 &= 460 \\
x_1 + 4(x_2' - x_2'') + s_3 &= 420 \\
x_1, x_2', x_2'', x_3, x_4, s_1, s_2, s_3 &\ge 0
\end{aligned}$$
