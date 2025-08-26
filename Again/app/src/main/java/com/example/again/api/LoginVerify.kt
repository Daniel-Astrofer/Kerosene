package com.example.again.api
import cash.z.ecc.android.bip39.Mnemonics


fun gerarFraseBip39(): String {
    return Mnemonics.MnemonicCode(Mnemonics.WordCount.COUNT_18)
        .joinToString(" ") { it.toString() }
}


