# Collide, Collate, Collect: Recognizing Senders in Wireless Collisions

Bachelor Thesis by Johannes Lauinger


## Metadata

Submitted: August 10th, 2017

Advisor: Prof. Dr.-Ing. Matthias Hollick  
Supervisor: Robin Klose, M.Sc.

Secure Mobile Networking Lab  
Department of Computer Science  
Technische Universität Darmstadt


## Repository Structure


## Abstract

With wireless mobile IEEE 802.11a/g networks, collisions are currently inevitable de-
spite effective counter measures. This work proposes an approach to detect the MAC
addresses of transmitting stations in case of a collision, and measures its practical feasi-
bility. Recognizing senders using cross-correlation in the time domain worked surpris-
ingly well in simulations using Additive White Gaussian Noise (AWGN) and standard
Matlab channel models.

Real-world experiments using software-defined radios also showed promising results
in spite of decreased accuracy due to channel effects. During the experiments, various
Modulation and Coding Schemes (MCSs) and scrambler initialization values were com-
pared. Knowledge about which senders were transmitting leading up to a collision could
help develop new improvements to the 802.11 MAC coordination function, or serve as a
feature for learning-based algorithms.


## Zusammenfassung

In drahtlosen mobilen Netzwerken nach den IEEE 802.11a/g Standards sind Kollisionen
trotz wirkungsvoller Gegenmaßnahmen nicht vollständig zu vermeiden. Diese Arbeit
stellt einen Ansatz zur Erkennung der MAC-Adressen der beteiligten Sender bei einer
Kollision vor und untersucht, inwiefern das Verfahren in der Praxis funktioniert. Über
Kreuzkorrelation im Zeitbereich funktionierte die Erkennung in Simulationen unter Ad-
ditivem Weißen Gaußschen Rauschen (AWGN) und verschiedenen Standard-Kanalmodellen
von Matlab erstaunlich gut.

Praktische Experimente mit Software-Defined Radios zeigten ebenfalls vielversprechen-
de Ergebnisse, wenn auch die Genauigkeit der Erkennung durch Kanaleffekte beein-
trächtigt wurde. Bei den Experimenten wurden verschiedene Modulation and Coding
Schemes (MCSs) und Scrambler-Initialisierungen verglichen. Die Kenntnis über die be-
teiligten Sender bei einer Kollision könnte zur Verbesserung der Koordinierungsfunkti-
on oder als Feature für lernbasierte Verfahren verwendet werden.


## License

Copyright (c) 2017 Johannes Lauinger
