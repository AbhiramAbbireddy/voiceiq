package com.voiceiq.backend;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BackendApplicationTests {

    @Test
    void applicationNameIsStable() {
        assertEquals("com.voiceiq.backend.BackendApplication", BackendApplication.class.getName());
    }
}
