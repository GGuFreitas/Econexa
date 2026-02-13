// backend/src/main/java/com/econexa/controller/MarcadorController.java
package com.econexa.controller;

import com.econexa.model.Marcador;
import com.econexa.repository.MarcadorRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/marcadores")
@CrossOrigin(origins = "*")
public class MarcadorController {

    @Autowired
    private MarcadorRepository marcadorRepository;

    @GetMapping
    public ResponseEntity<List<Marcador>> listarTodos() {
        return ResponseEntity.ok(marcadorRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Marcador> buscarPorId(@PathVariable UUID id) {
        return marcadorRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/proximos")
    public ResponseEntity<List<Marcador>> listarProximos(
            @RequestParam Double lat,
            @RequestParam Double lng,
            @RequestParam(defaultValue = "10") Double raio) {
        return ResponseEntity.ok(marcadorRepository.findByProximidade(lat, lng, raio));
    }

    @GetMapping("/cidade/{cidade}")
    public ResponseEntity<List<Marcador>> listarPorCidade(@PathVariable String cidade) {
        return ResponseEntity.ok(marcadorRepository.findByCidade(cidade));
    }
}