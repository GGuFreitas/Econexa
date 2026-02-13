// backend/src/main/java/com/econexa/model/Marcador.java
package com.econexa.model;

import com.econexa.model.enums.StatusMarcador;
import com.econexa.model.enums.TipoMarcador;
import jakarta.persistence.*;
import java.awt.Point;

import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;


import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "marcadores")
@Data
public class Marcador {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String titulo;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String descricao;

    @Column(nullable = false, precision = 10, scale = 8)
    private Double latitude;

    @Column(nullable = false, precision = 11, scale = 8)
    private Double longitude;

    @Column(columnDefinition = "geometry(Point,4326)")
    private Point pontoGeografico;

    private String endereco;
    private String bairro;

    @Column(nullable = false)
    private String cidade;

    @Column(nullable = false, length = 2)
    private String estado;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "categoria_id")
    private Categoria categoria;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TipoMarcador tipo;

    @Enumerated(EnumType.STRING)
    private StatusMarcador status = StatusMarcador.ATIVO;

    private Integer urgencia = 1;

    private Integer votosPositivos = 0;
    private Integer votosNegativos = 0;
    private Integer visualizacoes = 0;
    private Integer compartilhamentos = 0;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @CreationTimestamp
    private LocalDateTime criadoEm;

    @UpdateTimestamp
    private LocalDateTime atualizadoEm;

    private LocalDateTime dataOcorrencia;

    private String uuidPublico;
}