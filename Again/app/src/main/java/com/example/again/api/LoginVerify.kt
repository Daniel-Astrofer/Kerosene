package com.example.again.api
import cash.z.ecc.android.bip39.Mnemonics
import java.security.MessageDigest


fun gerarFraseBip39(): String {
    return Mnemonics.MnemonicCode(Mnemonics.WordCount.COUNT_18)
        .joinToString(" ") { it.toString() }
}


fun hash(input : String): String {

    val bytes = input.toByteArray()
    val md = MessageDigest.getInstance("SHA-256")
    val digest = md.digest(bytes)

    return digest.joinToString(""){"%02x".format(it)}

}