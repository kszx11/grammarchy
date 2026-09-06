# Bundled parser notices

## UDPipe 1.4.0

`linux-x86_64/udpipe` is the unmodified `bin-linux64/udpipe` member from the
official [UDPipe 1.4.0 release](https://github.com/ufal/udpipe/releases/tag/v1.4.0).
It is licensed under the Mozilla Public License 2.0. The complete source and
binary provenance chain, including release-archive and source checksums, is
in [`docs/BUILD_PROVENANCE.md`](../docs/BUILD_PROVENANCE.md). The full license
text is included at [`licenses/MPL-2.0.txt`](licenses/MPL-2.0.txt).

Binary SHA-256:

```text
8770ff2114258a1df1ea8403dcbea92d3336ab6d3e420499d57c54e3dea6a11b
```

## English UD model

`linux-x86_64/english-ewt.udpipe` is the `english-ud-2.1-20180111` model from
the `bnosac/udpipe.models.ud` project. The project attributes it to the UD
English data and FastText vectors and licenses the model under CC BY-SA 4.0.
See its [credits](https://github.com/bnosac/udpipe.models.ud/blob/master/src/english/CREDITS.md)
and [license](https://github.com/bnosac/udpipe.models.ud/blob/master/src/english/LICENSE).
The full CC BY-SA 4.0 legal code is included at
[`licenses/CC-BY-SA-4.0.txt`](licenses/CC-BY-SA-4.0.txt).

Model SHA-256:

```text
20432a6f87b1f258927207b8fbd2dc21ebff9722b381b7a36cef34c8c9a380dc
```

The model is distributed unmodified. Grammarchy supports Linux x86_64 with
this artifact; unsupported architectures use the clearly labelled local
fallback until a matching artifact is released.
