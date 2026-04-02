package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.StoreSettingsRequest;
import com.oraiopoli.supermarket.entity.StoreSettings;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.StoreSettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StoreSettingsService {

    private final StoreSettingsRepository settingsRepository;

    public Map<String, String> getAllSettings() {
        return settingsRepository.findAll().stream()
                .collect(Collectors.toMap(StoreSettings::getKey, s -> s.getValue() != null ? s.getValue() : ""));
    }

    public String getSetting(String key) {
        StoreSettings setting = settingsRepository.findByKey(key)
                .orElseThrow(() -> new ResourceNotFoundException("Setting", "key", key));
        return setting.getValue();
    }

    public String getSettingOrDefault(String key, String defaultValue) {
        return settingsRepository.findByKey(key)
                .map(StoreSettings::getValue)
                .orElse(defaultValue);
    }

    @Transactional
    public StoreSettings upsertSetting(StoreSettingsRequest request) {
        StoreSettings setting = settingsRepository.findByKey(request.getKey())
                .orElse(StoreSettings.builder().key(request.getKey()).build());

        setting.setValue(request.getValue());
        setting.setDescription(request.getDescription());

        return settingsRepository.save(setting);
    }

    @Transactional
    public void deleteSetting(String key) {
        StoreSettings setting = settingsRepository.findByKey(key)
                .orElseThrow(() -> new ResourceNotFoundException("Setting", "key", key));
        settingsRepository.delete(setting);
    }
}

