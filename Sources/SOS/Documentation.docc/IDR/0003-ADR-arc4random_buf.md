# Programmiersprache Swift

Die Implementierung erfolgt mit dem ASCON-PRF Algorithmus (KI generiert).

## Entscheidung

✅ ASCON 

❌ ChaCha20

❌ Xoodoo

## Optionen

ASCON wurde 2014 von einem österreichisch-deutschen Team entwickelt: Christoph Dobraunig, Maria Eichlseder, Florian Mendel und Martin Schläffer (TU Graz + IAIK). 2023 wurde es vom NIST als Lightweight Cryptography Standard ausgewählt — nach einem 7-jährigen Auswahlprozess mit 57 Kandidaten.

Explizit für eingeschränkte Umgebungen designed: Microcontroller, IoT, Embedded Systems. Nicht als Ersatz für AES, sondern für Szenarien wo AES zu schwer ist — was es für uns besonders interessant macht.

ASCON ist nicht nur ein Algorithmus sondern eine Familie:
| Variante | Zweck |
| --- | --- |
| ASCON-128 | Authenticated Encryption (AEAD) |
| ASCON-128a | AEAD, schnellere Rate |
| ASCON-Hash | Kryptografisches Hashing |
| ASCON-XOF | Extendable Output Function |
| ASCON-PRF | Pseudorandom Function |

Wir nutzen ASCON im Wesentlichen als PRF/PRNG — nicht für seinen eigentlichen AEAD-Zweck. Das ist legitim und gut dokumentiert, entspricht aber nicht dem NIST-Standard-Usecase. ASCON-XOF wäre die formell korrektere Basis für einen PRNG.

Vergleich mit unseren Alternativen
| | ChaCha20 | Xoodoo | ASCON |
| --- | --- | --- | --- |
| State | 512-bit | 384-bit | 320-bit |
| Wortbreite | 32-bit | 32-bit | 64-bit |
| Runden | 20 | 12 | 12 |
| Output/Runde | 512-bit | 384-bit | 192-bit |
| NIST Standard | ❌ | ❌ | ✅ 2023 |
| Sponge | ❌ | ❌ | ✅ |
| AArch64 nativ | teilweise | teilweise | vollständig |

Der einzige echte Nachteil gegenüber ChaCha20 und Xoodoo ist der niedrigere Output pro Permutation (192-bit vs 384/512-bit) — dafür ist jedes dieser Bits kryptografisch stärker abgesichert durch die Capacity.
