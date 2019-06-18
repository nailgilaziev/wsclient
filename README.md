# wsclient

ws test application

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.


Соглашения по поддержке и оформлению кода комментариями:

Слеши с отступом на текущем уровне от края:
    // используется для двух случаев:
    // ignore: avoid_using_as - для suppress lint warnings
    // для временных комментариев во время разработки в основном как продолжение текста TODO

Слеши без отступа от края:
//     коментирование кода через cmd+/ слеши ставит в самом начале строки
//     ws.add(json)
//     код, который временно выключается (а возможно и не включится больше) комментировать только таким образом.
//     Это позволит быстро глазами найти в коде мертвые и уже не актуальные линии.
//     Опционально можно снабжать такой код TODO пояснениями что сделать в будущем с этой строкой

Три слеша с отступом на текущем уровне от края:
    /// комментарии которые поясняют действующий код оставлять тремя слешами (это пояснение - документирование)
    /// такие пояснения выделяются зеленым цветом и являются частью постоянного кода,
    /// который просто нуждается в постоянном сопровождении его текстовым описанием.
    /// описывать так не только функции и классы, но так же и строки кода внутри них.
    /// традиционно описание/документирование предшествует блоку кода.
    /// они не являются "временными" комментариями, являются документацией и  оформляются соответственно

