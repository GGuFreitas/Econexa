// backend/src/main/java/com/econexa/repository/MarcadorRepository.java
package com.econexa.repository;

import com.econexa.model.Marcador;
import com.econexa.model.enums.StatusMarcador;
import com.econexa.model.enums.TipoMarcador;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MarcadorRepository extends JpaRepository<Marcador, UUID> {

    List<Marcador> findByTipo(TipoMarcador tipo);

    List<Marcador> findByStatus(StatusMarcador status);

    List<Marcador> findByCidade(String cidade);

    @Query(value = "SELECT * FROM marcadores m WHERE " +
            "calcular_distancia_km(:latitude, :longitude, m.latitude, m.longitude) <= :raio " +
            "AND m.status = 'ATIVO' " +
            "ORDER BY calcular_distancia_km(:latitude, :longitude, m.latitude, m.longitude)", nativeQuery = true)
    List<Marcador> findByProximidade(
            @Param("latitude") Double latitude,
            @Param("longitude") Double longitude,
            @Param("raio") Double raio
    );

    @Query("SELECT m FROM Marcador m WHERE m.usuario.id = :usuarioId ORDER BY m.criadoEm DESC")
    List<Marcador> findByUsuarioId(@Param("usuarioId") UUID usuarioId);
}