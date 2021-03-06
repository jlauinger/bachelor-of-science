# Collide, Collate, Collect: Recognizing Senders in Wireless Collisions

Bachelor Thesis by Johannes Lauinger

Submitted: August 10th, 2017

Advisor: Prof. Dr.-Ing. Matthias Hollick  
Supervisor: Robin Klose, M.Sc.

Secure Mobile Networking Lab  
Department of Computer Science  
Technische Universität Darmstadt


## Citation

Cite this work as follows:

 - Lauinger, Johannes Tobias. "Collide, Collate, Collect: Recognizing Senders in Wireless Collisions." B.Sc. Thesis. Technische Universität Darmstadt, 2017.

BibTex:

```latex
@mastersthesis{lauinger2017,
    type    = {B.Sc. Thesis},
    author  = {Lauinger, Johannes Tobias},
    title   = {Collide, Collate, Collect: Recognizing Senders in Wireless Collisions},
    school  = {Technische Universität Darmstadt},
    year    = {2017},
    pdf     = {https://tubama.ulb.tu-darmstadt.de/253/1/lauinger2017-sender-recognition.pdf}
}
```

Note: the full-text PDF version is only accessible from within the TU Darmstadt network.


## Repository Structure

The `implementation` directory contains the Matlab code that I wrote to conduct experiments
for this thesis. **Some files, starting with seemoo\_, can however not be used directly**. This
is due to a dependency to an internal library from the SEEMOO Lab at TU Darmstadt that I
couldn't include in this repository. Furthermore, there is a couple of calls to functions
starting with ieee\_80211\_. The implementation of those functions is missing.

The LaTeX files and assets for the thesis document, as well as my presentations, are located
in the `thesis` directory. The final thesis document is included in PDF format in the top-level
directory.

Note: During the work on this thesis, there were two different repositories for implementation
and thesis. I attempted to merge those, so there may be some strange things and/or consistency
errors in the Git history.

Some data has been redacted, for example the MAC addresses that I captured with `airodump-ng`
in `data/`. This is due to obvious privacy concerns.


## Abstract

With wireless mobile IEEE 802.11a/g networks, collisions are currently inevitable despite
effective counter measures. This work proposes an approach to detect the MAC
addresses of transmitting stations in case of a collision, and measures its practical
feasibility. Recognizing senders using cross-correlation in the time domain worked surprisingly
well in simulations using Additive White Gaussian Noise (AWGN) and standard Matlab channel
models.

Real-world experiments using software-defined radios also showed promising results
in spite of decreased accuracy due to channel effects. During the experiments, various
Modulation and Coding Schemes (MCSs) and scrambler initialization values were compared.
Knowledge about which senders were transmitting leading up to a collision could
help develop new improvements to the 802.11 MAC coordination function, or serve as a
feature for learning-based algorithms.


## Zusammenfassung

In drahtlosen mobilen Netzwerken nach den IEEE 802.11a/g Standards sind Kollisionen
trotz wirkungsvoller Gegenmaßnahmen nicht vollständig zu vermeiden. Diese Arbeit
stellt einen Ansatz zur Erkennung der MAC-Adressen der beteiligten Sender bei einer
Kollision vor und untersucht, inwiefern das Verfahren in der Praxis funktioniert. Über
Kreuzkorrelation im Zeitbereich funktionierte die Erkennung in Simulationen unter
Additivem Weißen Gaußschen Rauschen (AWGN) und verschiedenen Standard-Kanalmodellen
von Matlab erstaunlich gut.

Praktische Experimente mit Software-Defined Radios zeigten ebenfalls vielversprechende
Ergebnisse, wenn auch die Genauigkeit der Erkennung durch Kanaleffekte beeinträchtigt
wurde. Bei den Experimenten wurden verschiedene Modulation and Coding
Schemes (MCSs) und Scrambler-Initialisierungen verglichen. Die Kenntnis über die
beteiligten Sender bei einer Kollision könnte zur Verbesserung der Koordinierungsfunktion
oder als Feature für lernbasierte Verfahren verwendet werden.


## License

Copyright (c) 2017 Johannes Lauinger  

### Thesis Document and Source Code

<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/"><img alt="Creative Commons Lizenzvertrag" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/">Creative Commons Attribution-NonCommercial-NoDerivs  4.0 International License</a>.

### Matlab Implementation

Licensed under the terms of the <a rel="license" href="https://www.gnu.org/licenses/gpl-3.0.en.html">GNU GENERAL PUBLIC LICENSE, Version 3</a>.
