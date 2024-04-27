/// @diagnostic disable:lowercase-global
/// @file

/// @class MyArray<T>: { [integer]: T }

/// @class MyDictionary<T>: { [string]: T }

///
/// @class MyArray
///
/// @brief
template <typename T>
class MyArray : public Table<integer, T> {

};

///
/// @class MyDictionary
///
/// @brief
template <typename T>
class MyDictionary : public Table<string, T> {

};

/// @brief
/// Generic array.
/// @param aaa (MyArray<string>) Array of strings.
/// @returns (nil) 
(nil) gen01(MyArray<string> aaa);

/// @brief
/// Generic array.
/// @param aaa (MyArray<integer>) Array of integer.
/// @returns (nil) 
(nil) gen02(MyArray<integer> aaa);

/// @brief
/// Generic dictionary.
/// @param aaa (MyDictionary<string>) Dictionary of strings.
/// @returns (nil) 
(nil) gen02(MyDictionary<string> aaa);

