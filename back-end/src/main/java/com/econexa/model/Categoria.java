// backend/src/main/java/com/econexa/model/Categoria.java
package com.econexa.model;

import com.econexa.model.enums.TipoCategoria;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "categorias")
@Data
public class Categoria {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String nome;

    private String descricao;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TipoCategoria tipo;

    private String icone;
    private String corHex;
    private Integer ordem = 0;
    private Boolean ativo = true;

    @CreationTimestamp
    private LocalDateTime criadoEm;
}