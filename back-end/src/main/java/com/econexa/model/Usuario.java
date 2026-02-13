// backend/src/main/java/com/econexa/model/Usuario.java
package com.econexa.model;

import com.econexa.model.enums.TipoUsuario;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "usuarios")
@Data
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(unique = true, nullable = false)
    private String email;

    @JsonIgnore
    @Column(nullable = false)
    private String senha;

    @Column(nullable = false)
    private String nome;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TipoUsuario tipo = TipoUsuario.COMUM;

    private String avatarUrl;
    private String biografia;
    private String telefone;
    private String cidade;
    private String estado;

    private Boolean verificado = false;
    private Boolean ativo = true;
    private Integer reputacao = 0;

    private Integer problemasReportados = 0;
    private Integer problemasResolvidos = 0;
    private Integer eventosParticipados = 0;

    @CreationTimestamp
    private LocalDateTime criadoEm;

    @UpdateTimestamp
    private LocalDateTime atualizadoEm;

    private LocalDateTime ultimoLogin;
}