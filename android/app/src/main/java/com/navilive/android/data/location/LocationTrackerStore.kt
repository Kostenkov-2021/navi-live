package com.navilive.android.data.location

import com.navilive.android.model.LocationFix
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class TrackerState(
    val latestFix: LocationFix? = null,
    val isTracking: Boolean = false,
)

object LocationTrackerStore {
    private val _state = MutableStateFlow(TrackerState())
    private val stabilizer = LocationFixStabilizer()
    val state: StateFlow<TrackerState> = _state.asStateFlow()

    @Synchronized
    fun setTracking(enabled: Boolean) {
        if (!enabled) {
            stabilizer.reset()
        }
        _state.update { current -> current.copy(isTracking = enabled) }
    }

    @Synchronized
    fun pushFix(fix: LocationFix) {
        val stabilizedFix = stabilizer.stabilize(fix) ?: return
        _state.update { current -> current.copy(latestFix = stabilizedFix) }
    }
}
