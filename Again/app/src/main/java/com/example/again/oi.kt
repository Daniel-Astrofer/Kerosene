package com.example.again

import android.R.attr.name
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class oi: ViewModel(){
    private val _name =  MutableStateFlow("")
    val name : StateFlow<String> = _name

    fun set(new : String){
        _name.value = new
    }


}