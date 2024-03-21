/// @file

/// @brief
/// @param foo (T) generic T
/// @param x (integer) 
/// @returns (T) generic T
template <typename T>
(T) gen01(T foo, integer x);

/// @brief
/// @param foo (T❲❳) generic array
/// @returns (T❲❳) generic array
template <typename T>
(T❲❳) gen02(T❲❳ foo);

/// @brief
/// @param foo (T→number) 
/// @returns (T→number) 
template <typename T→number>
(T→number) gen03(T→number foo);

/// @brief
/// @param foo (T1) 
/// @param bar (T2) 
/// @param xox (T3) 
template <typename T1, typename T2, typename T3>
gen04(T1 foo, T2 bar, T3 xox);

